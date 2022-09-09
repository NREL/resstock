# python version of run_sampling.rb
# Author: Rajendra.Adhikari@nrel.gov

import argparse
import pathlib
import pandas as pd
import networkx as nx
import numpy as np
import time
from joblib import Parallel, delayed
import itertools as it
import multiprocessing
import random


random.seed(42)

def read_char_tsv(file_path):
    dep_cols = []
    opt_cols = []
    group2probs = {}
    with open(file_path) as file:
        for indx, line in enumerate(file):
            if line[0] == '#':
                continue
            if indx==0:
                for header in line.split("\t"):
                    if header[:11] == "Dependency=":
                        dep_col = header[11:]
                        dep_cols.append(dep_col)
                    elif header[:7] == "Option=":
                        opt_col = header[7:]
                        opt_cols.append(opt_col)
            else:
                line_array = line.split("\t")
                dep_val = tuple(line_array[:len(dep_cols)])
                opt_val = [float(v) for i, v in enumerate(line_array[len(dep_cols):len(dep_cols)+len(opt_cols)])
                           if opt_cols[i] != 'Void']
                if 'Void' in opt_cols:
                    opt_cols.remove('Void')
                group2probs[dep_val] = opt_val
    return group2probs, dep_cols, opt_cols

def get_param2tsv(opt_lookup_df: pd.DataFrame, characteristics_dir: pathlib.Path):
    unique_params = opt_lookup_df.loc[:, "Parameter Name"].unique()
    param2tsv_path = {param: tsv_path for param in unique_params if (tsv_path:=characteristics_dir / f"{param}.tsv").exists()}
    param2tsv = {}
    with Parallel(n_jobs=-2, verbose=9) as parallel:
        def read_tsv(param, tsv_path):
            return (param, read_char_tsv(tsv_path))
        res = parallel(map(delayed(read_tsv), *zip(*param2tsv_path.items())))
    param2tsv = {param: tsv for param, tsv in res}
    return param2tsv


def get_param_graph(param2dep):
    param2dep_graph = nx.DiGraph()
    for param, dep_list in param2dep.items():
        param2dep_graph.add_node(param)
        for dep in dep_list:
            param2dep_graph.add_edge(dep, param)
    return param2dep_graph

def get_topological_param_list(param2dep):
    param2dep_graph = get_param_graph(param2dep)
    topo_params = list(nx.topological_sort(param2dep_graph))
    return topo_params

def get_topological_generations(param2dep):
    param2dep_graph = get_param_graph(param2dep)
    return enumerate(nx.topological_generations(param2dep_graph))

def get_samples(probs, options, num_samples):
    prob_options = list(sorted(zip(probs, options), key=lambda x: x[0], reverse=True))
    if num_samples < len(prob_options):
        prob_options = prob_options[0:num_samples]
    probs, options = zip(*prob_options)
    probs = np.array(probs)
    sample_dist = probs*num_samples/sum(probs)
    allocations = np.floor(sample_dist).astype(int)  # Assign integer number of samples at first
    remaining_samples = num_samples - int(sum(allocations))
    remaining_allocation = sample_dist - allocations
    extra_opts = sorted(enumerate(remaining_allocation), key=lambda x: x[1], reverse=True)[0:remaining_samples]
    for indx, _ in extra_opts:
       allocations[indx] += 1

    samples = []
    for (indx, count) in enumerate(allocations):
        samples.extend([options[indx]] *count)
    random.shuffle(samples)
    return samples


def sample(param_tuple, sample_df, param:str, num_samples:int):
    start_time = time.time()
    group2values, dep_cols, opt_cols = param_tuple
    if not dep_cols:
        probs = group2values[()]
        samples = get_samples(probs, opt_cols, num_samples)
    else:
        grouped_df = sample_df.groupby(dep_cols, sort=False)
        prob_list = []
        sample_size_list = []
        index_list = []
        for group_key, indexes in grouped_df.groups.items():
            group_key = group_key if isinstance(group_key, tuple) else (group_key,)
            index_list.append(indexes)
            probs = group2values[group_key]
            prob_list.append(probs)
            sample_size_list.append(len(indexes))

        samples_list = map(get_samples, prob_list, it.cycle([opt_cols]), sample_size_list)
        flat_samples = []
        for indexes, samples in zip(index_list, samples_list):
            flat_samples.extend(list(zip(indexes, samples)))
        samples = [s[1] for s in sorted(flat_samples)]
    print(f"Returning samples for {param} in {time.time() - start_time:.2f}s")
    return samples

def run_sampling(project_name, num_samples, output_file):
    resources_dir = pathlib.Path(__file__).parent
    characteristics_dir = resources_dir.parent / project_name / "housing_characteristics"
    lookup_file = resources_dir / "options_lookup.tsv"
    lookup_csv_data = pd.read_csv(lookup_file, delimiter="\t")
    print("Getting Pram2tsv")
    s_time = time.time()  
    param2tsv = get_param2tsv(lookup_csv_data, characteristics_dir)
    print(f"Got Param2tsv in {time.time()-s_time:.2f} seconds")
    param2dep = {param:tsv_tuple[1] for (param, tsv_tuple) in param2tsv.items()}
    sample_df = pd.DataFrame()
    sample_df.loc[:, "Building"] = list(range(1,num_samples+1))
    s_time = time.time()
    with multiprocessing.Pool(processes=max(multiprocessing.cpu_count() - 2, 1)) as pool:
        for level, params in get_topological_generations(param2dep):
            print(f"Sampling {len(params)} params in a batch at level {level}")
            results = []
            for param in params:
                _, dep_cols, _ = param2tsv[param]
                res = pool.apply_async(sample, (param2tsv[param], sample_df[dep_cols], param, num_samples))
                results.append(res)

            print(f"Submitted {len(results)} params in a batch")
            st = time.time()
            samples_dict = {param:res_val.get() for param, res_val in zip(params, results)}
            print(f"Got results for {len(samples_dict)} params in {time.time()-st:.2f}s")
            assert len(samples_dict) == len(params)
            new_df = pd.DataFrame(samples_dict)
            sample_df = pd.concat([sample_df, new_df], axis=1)
    print(f"Sampled in {time.time()-s_time:.2f} seconds")
    print("Writing CSV")
    sample_df.to_csv(output_file, index=False)
    print(f"Done sampling {len(param2dep)} TSVs with {num_samples} samples.")
    
if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description='Run Sampling')
    parser.add_argument('-p', '--project', metavar='project_name', type=str,
                        default="project_national",
                        help='The resstock project to sample')
    parser.add_argument('-n', '--num-datapoints', metavar='n_datapoints', type=int,
                        default=100000,
                        help='The number of datapoints to sample.')
    parser.add_argument('-o', '--output', metavar='output_file', type=str,
                        default="samples100K_py_multi.csv",
                        help='The output file name.')

    args = parser.parse_args()
    start_time = time.time()
    nsamples = args.num_datapoints
    run_sampling(args.project,nsamples, args.output)
    print(f"Completed sampling in {time.time() - start_time:.2f} seconds")
