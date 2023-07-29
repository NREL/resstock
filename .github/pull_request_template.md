## Pull Request Description

[description here]

## Checklist

Not all may apply:

- [ ] Tests (and test files) have been updated
- [ ] Documentation has been updated
  - [ ] If related to resstock-estimation, checklist includes [data dictionary](https://github.com/NREL/resstock/tree/develop/resources/data/dictionary), [source report](https://github.com/NREL/resstock/blob/447a86fb7754837f9b6fbadc586ce546b2a7224f/project_national/resources/source_report.csv), [options_lookup](https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv).
  - [ ] If changes to project_testing tsvs, checklist includes [yml_precomputed](https://github.com/NREL/resstock/tree/develop/test/tests_yml_files/yml_precomputed), [yml_precomputed_outdate](https://github.com/NREL/resstock/tree/develop/test/tests_yml_files/yml_precomputed_outdated), [yml_precomputed_weight](https://github.com/NREL/resstock/tree/develop/test/tests_yml_files/yml_precomputed_weight)
- [ ] Changelog has been updated
- [ ] `openstudio tasks.rb update_measures` has been run
- [ ] No unexpected regression test changes on CI (checked comparison artifacts)
