# -*- coding: utf-8 -*-s
'''
Created on Apr 29, 2014
@author: ewilson
      : jalley
'''
#future is the missing compatibility layer between Python 2 and Python 3.
#It allows you to use a single, clean Python 3.x-compatible codebase to support both Python 2 and Python 3 with minimal overhead.
from __future__ import division

#OS
#The OS module in Python provides a way of using operating system dependent functionality.
#The functions that the OS module provides allows you to interface with the
#underlying operating system that Python is running on – be that Windows, Mac or Linux.

#Sys
#This module provides access to some variables used or maintained by the interpreter
#  and to functions that interact strongly with the interpreter. It is always available.
import os, sys
import pandas as pd
from datetime import datetime
import psycopg2 as pg
import numpy as np
import sqlite3

con = sqlite3.connect('../../../../BEopt-dev/Build/BEopt/Data/Measures.sqlite')
Category = pd.read_sql_query('SELECT CategoryID, CategoryName from Category', con)
Option = pd.read_sql_query('SELECT OptionGUID, OptionName from Option', con)

con = sqlite3.connect('../../../../Users/jrobert1/Downloads/Output_2016-01-27_1m_EPSA_LEDDWCW.sqlite/Output.sqlite')
BEoptCategoryDependency = pd.read_sql_query('SELECT * from BEoptCategoryDependency', con)
MetaCategory = pd.read_sql_query('SELECT * from MetaCategory', con)
MetaOption = pd.read_sql_query('SELECT ID, MetaCategoryID, Name from MetaOption', con)
MetaOptionCombo = pd.read_sql_query('SELECT * from MetaOptionCombo', con)
OutputArchetypeVariant = pd.read_sql_query('SELECT * from OutputArchetypeVariant', con)
BEoptWeightingFactor = pd.read_sql_query('SELECT * from BEoptWeightingFactor', con)
EPWs = MetaOption[MetaOption['MetaCategoryID' ]= =1]['Name'].values
OutputArchetypeVariantOptionDiff = pd.read_sql_query \
    ('SELECT * from OutputArchetypeVariantOptionDiff where CategoryID in (190, 270, 375, 35, 312, 431, 367, 308, 316, 18, 374, 279)', con)

def main(df):

    # assign variant ids based on meta
    if not os.path.exists('recs.csv'):
        # meta
        df = assign_epw_stations(df)
        df = assign_location(df)
        df = assign_vintage(df)
        df = assign_heating_fuel(df)
        df = assign_size(df)
        df = assign_stories(df)
        df = assign_foundation_type(df)
        df = assign_daytime_occupancy(df)
        df = assign_usage_level(df)
        df = assign_attached_garage(df)
        df = assign_variant_ids(df)
        # for option in ['Water Heater', 'Windows', 'Cooking Range', 'Clothes Dryer', 'Refrigerator', 'Lighting', 'Dishwasher', 'Clothes Washer', 'Central Air Conditioner', 'Room Air Conditioner', 'Furnace', 'Boiler', 'Electric Baseboard', 'Air Source Heat Pump']:
        # print option
        # df = assign_option_guids(df, option)
        df.to_csv('recs.csv', index=False)
    else:
        df = pd.read_csv('recs.csv', index_col=['doeid'])

    # revise (remove) variant ids based on non-meta
    df['OutputArchetypeVariantID (Meta Parameters + Heating + Cooling + WH + Windows + CD + CR)'] = df
        ['OutputArchetypeVariantID (Meta Parameters)']

    guid_dict = {
        'Windows': {
            1: ['89719723-aff1-44cc-b1b9-65b84e300b89', 'be3d7bd5-2bac-48a5-b31e-6e0b6177b96b', '6414edb2-ab1b-4b81-bc14-77060e95f380', 'c8bc4c8b-a641-458c-b675-a0a397771fbe'],
            2: ['f16d0746-783e-47a0-9811-e0afaa3a1648', 'eedcb2ed-aff8-4477-a172-54a0f947ea6d', '1d43bb73-5954-44e9-a9c5-9b7bf8cc9d27', '97cc159d-8212-4bbc-8f9c-998ddaf4ae3f', 'db1bf549-f1db-44a5-a241-ae12b090c256', '90be778d-7d9d-402f-8039-28d359ae0063', '3c88c6b9-42a2-4b1a-a262-c877247ee4b8', 'e653e186-c90f-4bff-8b15-9cd82d21d331', '0a6b5f98-48d3-4ce0-b045-234aff403311', '74eca124-7291-412f-8ca0-b39041177f43', '6695a24c-1489-42ce-bafc-964a91bf0937', '61414c51-9177-486e-bab1-4b90f2f07d59', '0e9a779d-44f4-4032-93ba-0aa7bf751e8f', 'd6ff9fab-df3e-4cbd-a217-930d54532bdf', 'd25876f0-de98-4312-ac61-e9997d184a7f', '96e172f2-78a1-4b5d-8a35-f5f11bdcc151', '50cac643-bdbb-46f3-a4c7-332763afd0f2'],
            3: ['c9e5ce04-f311-4997-ad3e-93f85a263e9c', 'be746a7f-5379-4855-b337-7ae5d933798d', '21a41dc1-42d9-42f3-8ad5-19edac99c381', '0522fed1-ae94-483c-991f-e2f1df7ff3d3', '361d6a89-2b9f-40af-9e9e-9604510e2884', 'ddf2f25d-6be0-4a2c-813c-be4e50b45c52', 'd7f6e0fa-0130-4850-befe-bda4e2d0a9c9', '8561052c-3d69-471b-8d58-6ead30f12090'],
            -2: []
        },
        'Water Heater': {
            1: ['e8b153d5-6db6-4e06-9693-6b12cf3cc211', '7909986b-0650-44a3-a75b-0e3448b457e3', '0571556b-d601-4b7a-95c5-72579ec34dd2', 'eb4ce6f1-a81c-4a5f-bcda-79e7e6fb2368', 'a835f014-9483-4f1a-b455-81f357e22802', 'bebeaf92-c014-40fa-8c86-d788c94ffa44'],
            2: ['7f1cbf21-23c0-4206-8c70-1446ce698fff', 'd8f28637-b017-4586-9f9e-70438f748db2', 'e1626ddf-e5f0-45a4-a896-02cac4f88d27', '8c714ff0-4c01-4218-b942-313a6c8ad289'],
            3: ['1a0f39c6-148c-4fa9-837c-c300d74eab9f', 'd1c4f459-5680-4487-8bdf-b8aece15b824', '0b9bcec5-2720-49e1-9963-c8a396533f05'],
            5: ['145944ef-eef4-4d0a-b59b-476f5ef641d5', 'c85c9630-9b90-4afb-9f68-4f5d63aca2ba', 'b21ae540-2ef2-46ee-9c32-3e38367cd035', '2ef87841-d2c2-49df-86bb-6f745b13efda', '2e43df11-4a58-4206-a5d9-327bc351bed9', '70d3defd-454e-4066-b426-d1399c0fd332', 'ccc67b06-2296-40b4-8130-0f2bf5f92ee0', 'a2ef9609-c0b1-41f7-97c6-2bf74c162acf', '159f3791-aa74-43d8-8f76-98b927e6a5f0'],
            -2: ['15cdbe19-8803-4b53-9bae-1d77d026eaf7']
        },
        'Cooling System': {
            1: ['897f5198-2c44-4248-8833-3acbc3311b1b', 'd8d0e54a-ba4e-4a43-bb5b-b4eea7e197bc', '9cd14d0a-64df-4645-9177-8ef62d6b16df', '644afa47-528a-4a1e-b56e-c732ba978cc8', 'af0f2ca0-2fc7-414a-954b-cf7d3caa430d', '8fe5508b-3335-497c-9011-d8707cab9db3', 'bfa3d475-878f-43f2-ae90-9f1b4469cbe3', '9decd636-88ce-480b-b047-4f7249d011ce', '990efb7b-fb3b-4ded-88e9-a1c1e1092918', 'daa4b254-800d-4001-b685-4df1658bbda6', '77990573-b3b1-4e27-a98a-010dd9d3fbf8', 'eb255c43-3401-495a-a439-295962f09714', '524dbf58-e15b-4efb-9869-0d5fb38eb71d', '26f60d61-7a0f-4a94-89b7-77a8485bcf3c', '6eac3bac-ae1e-4285-aad2-3096d55eeaac', '09e3a6fa-8e74-4351-8698-0c7885e29829', '81a0aff5-7ccf-4740-8075-c100496d9ebd', '9dceb2c0-5086-4b5e-9869-a33bb5205359', '9501df06-0301-4f7b-b8de-06a8ffb02917', '9ecc8c61-b906-4bca-80e7-a2650605bda7', '10ec7bbe-41b0-47c7-9ea9-7be6e57c4664', '404e7cf5-105f-4993-80a1-1d8ecd279a53', 'd245c239-0eee-47a2-bff4-9b80c3b63284', '86d4be5b-a22d-4f3d-a2be-deb1a9a38994', '8e339243-d85b-4555-8ede-8a6bd6547e33', '3fb57d2a-1e7a-47da-a2b8-8125cd811a5c', 'b19b63c8-63ff-4212-a90e-271ce164e8e9', '833fa78c-9b76-40ab-a73c-15d7ae950606', 'dea6cfd2-5fb8-449c-b5c9-177d240f87eb', 'a8827370-7ce3-4d62-99d3-e144875dc127', 'a4d340ca-3426-4a51-8e0d-768f2caca036v', 'ca16959b-7373-47fd-a348-89dbcfb3ae04', 'c7292cb2-294b-4a01-bd94-7350faf9beab', '4e855906-9d35-4bc9-bf63-28027a0ae5a7', 'd82260f5-2f17-4e36-b6f2-c50d2d942b6c', '8eea660c-7786-46eb-91cd-ab650dcf6af9', '1d3675c8-b286-453c-96e1-90c0da25a811', '8c50111e-15d9-45fe-85ca-4e84492d05f3', '8f6ce499-3e8d-4de0-b22c-2c10152f7035', '7ca49c58-aea9-4aab-bc0f-c50bb019d441', '39ece60e-48ce-425c-8c21-d0a86e58ce30', '64343f52-61b1-4b1c-b565-1250b0493c79', '8da74897-0b70-4ad7-afce-cd061159b414', '82d00655-86e0-4b6d-9a95-d31fbf82425d', 'e635a861-7468-4fd1-b0e1-a6c89a166a46', '2478d1d4-ec0c-4c56-ac2b-8b00c37e829d', '1d8e5a39-d197-4f35-b6a6-5a99d0319cdf', 'df0618bb-121a-47f8-9123-e9254e4220a9'],
            2: ['2a995dd9-836a-476b-a269-a9bc99895cd7', '45478fcd-63c9-4d1c-9001-fc7dfcf4609d', '31cf9bf7-5144-4453-b415-cd3f275c3181', '810a1af0-7bc7-415c-9ebd-00d3d7f57e87', '647cf80b-0040-4f8c-8cb3-806ea273d86e', 'eccb2cd9-df91-44b8-9bc0-cde44982a24a', '49512ef4-b2e0-468e-b704-7c64be1e33de', 'b8fecb2f-cc7a-4c98-a05d-10b1ef186a50', '3183f79f-1d12-4112-b0cd-abdc107bd805'],
            3: ['897f5198-2c44-4248-8833-3acbc3311b1b', 'd8d0e54a-ba4e-4a43-bb5b-b4eea7e197bc', '9cd14d0a-64df-4645-9177-8ef62d6b16df', '644afa47-528a-4a1e-b56e-c732ba978cc8', 'af0f2ca0-2fc7-414a-954b-cf7d3caa430d', '8fe5508b-3335-497c-9011-d8707cab9db3', 'bfa3d475-878f-43f2-ae90-9f1b4469cbe3', '9decd636-88ce-480b-b047-4f7249d011ce', '990efb7b-fb3b-4ded-88e9-a1c1e1092918', 'daa4b254-800d-4001-b685-4df1658bbda6', '77990573-b3b1-4e27-a98a-010dd9d3fbf8', 'eb255c43-3401-495a-a439-295962f09714', '524dbf58-e15b-4efb-9869-0d5fb38eb71d', '26f60d61-7a0f-4a94-89b7-77a8485bcf3c', '6eac3bac-ae1e-4285-aad2-3096d55eeaac', '09e3a6fa-8e74-4351-8698-0c7885e29829', '81a0aff5-7ccf-4740-8075-c100496d9ebd', '9dceb2c0-5086-4b5e-9869-a33bb5205359', '9501df06-0301-4f7b-b8de-06a8ffb02917', '9ecc8c61-b906-4bca-80e7-a2650605bda7', '10ec7bbe-41b0-47c7-9ea9-7be6e57c4664', '404e7cf5-105f-4993-80a1-1d8ecd279a53', 'd245c239-0eee-47a2-bff4-9b80c3b63284', '86d4be5b-a22d-4f3d-a2be-deb1a9a38994', '8e339243-d85b-4555-8ede-8a6bd6547e33', '3fb57d2a-1e7a-47da-a2b8-8125cd811a5c', 'b19b63c8-63ff-4212-a90e-271ce164e8e9', '833fa78c-9b76-40ab-a73c-15d7ae950606', 'dea6cfd2-5fb8-449c-b5c9-177d240f87eb', 'a8827370-7ce3-4d62-99d3-e144875dc127', 'a4d340ca-3426-4a51-8e0d-768f2caca036v', 'ca16959b-7373-47fd-a348-89dbcfb3ae04', 'c7292cb2-294b-4a01-bd94-7350faf9beab', '4e855906-9d35-4bc9-bf63-28027a0ae5a7', 'd82260f5-2f17-4e36-b6f2-c50d2d942b6c', '8eea660c-7786-46eb-91cd-ab650dcf6af9', '1d3675c8-b286-453c-96e1-90c0da25a811', '8c50111e-15d9-45fe-85ca-4e84492d05f3', '8f6ce499-3e8d-4de0-b22c-2c10152f7035', '7ca49c58-aea9-4aab-bc0f-c50bb019d441', '39ece60e-48ce-425c-8c21-d0a86e58ce30', '64343f52-61b1-4b1c-b565-1250b0493c79', '8da74897-0b70-4ad7-afce-cd061159b414', '82d00655-86e0-4b6d-9a95-d31fbf82425d', 'e635a861-7468-4fd1-b0e1-a6c89a166a46', '2478d1d4-ec0c-4c56-ac2b-8b00c37e829d', '1d8e5a39-d197-4f35-b6a6-5a99d0319cdf', 'df0618bb-121a-47f8-9123-e9254e4220a9', '2a995dd9-836a-476b-a269-a9bc99895cd7', '45478fcd-63c9-4d1c-9001-fc7dfcf4609d', '31cf9bf7-5144-4453-b415-cd3f275c3181', '810a1af0-7bc7-415c-9ebd-00d3d7f57e87', '647cf80b-0040-4f8c-8cb3-806ea273d86e', 'eccb2cd9-df91-44b8-9bc0-cde44982a24a', '49512ef4-b2e0-468e-b704-7c64be1e33de', 'b8fecb2f-cc7a-4c98-a05d-10b1ef186a50', '3183f79f-1d12-4112-b0cd-abdc107bd805'],
            -2: ['bb199710-8eaf-40d6-be2f-1455054c293e', 'eb8e0cfd-f2d2-48cd-ac26-aad9a8d4f8cd', 'dd2e9fa7-3ee9-4669-b00a-b209ef5c509f']
        },
        'Heating System': {
            2: ['5d266af7-305c-4aa8-b047-3ec51cd86b3f', '61c805c3-c37b-43ab-95e0-d30fd320632e', '0709ccbb-6470-45fd-8530-d426554e2909', 'daced047-270a-4ae8-bea3-d93070ecb9dd', '21913d8c-3780-43ae-9244-84f3c5f1a012', '3f6bb1f5-90f8-4d86-b9e8-c6a179fe3e27', '698c9a7f-0d92-4fed-bc0d-35fe4fc94965', '25e931af-0c0a-4ca9-958b-00aab07153d0', '014e4320-7036-4ce3-b275-36d0bfc7a2c0', '0338c2e8-5653-4aa6-b875-8f4793d16e8b', 'bdcda0b0-6319-4643-86b1-a6faaa1ecd26', '702cb178-4cb5-420c-97b6-e8b7743a9c4d', 'a669ad3a-53dd-4b2e-9c0b-dde8beef6e7e', '06b0706d-1dfa-4f11-9b5c-1a47e8975734', '9f671960-2051-40cf-bdc9-e1adba049fcb', 'ffb71faa-66c7-45e1-bff2-2b81b3b7e9cc', '617b63e7-3ee8-4c83-a72e-d017aa8d37ba', '704c8d22-df56-4477-9b5f-9b0d61e5757a', 'd84a470b-5a5c-4b13-a5e9-6fd8fe5392b7', '7acd367a-c0d4-48f8-9565-afad18aed21d', 'dd89d4ef-0923-491c-95e0-f71d44124b23', '28536090-4199-4b3b-852f-c09021cf0ed9', '595ea600-671f-4eb6-a90d-d59b985b9f92', 'c9aa1970-1ad4-4154-adc0-b20b299834f3', 'e1d8e82-266e-463d-9029-932506a7a79d'],
            3: ['4f395284-d51c-4e16-80c6-a8175ec7b3cd', '39a55972-a18e-4e45-bb60-ac3b538de2c8', '6186dca5-d224-4bff-ad26-1c39d556f941', '3ea128d-0898-4f42-b218-eb002fdfc263', 'b0580fc1-bb7e-43fb-94ec-c59a347e834b', '84c0a4c2-4dc4-443b-ac06-4a87d9738b50', 'f6a94a33-2f10-4c26-91b3-067279e9533d', 'b1ed0adb-45f8-44c8-89e0-e78f2d568d8a', '8699db43-e5f5-44af-a74e-d873c5dcd1ff', '231168d9-c607-4cbf-9666-3f050810f09f', '06c323e8-8b62-4bbd-8258-d3eb8c50aebb', 'a55ca64d-6e0b-4fda-b5c5-4ac2ee5a6c58', '1088df4c-606b-4dce-9e6a-8876291ca747', 'da4844e0-2ae3-4a95-a0e2-513f3c25b1c7', '26012abb-3200-49b3-82c1-918df732072a', '4e1eae05-c8c3-4524-8d6a-00fece8bfa76', '2f32c62f-f201-43aa-ad48-4586750718fd', '891af30d-d33c-4f51-8612-8e141adde47b', '9d52b664-c587-4a2b-84a5-b9f2a5702dae', 'e7125162-3e79-4aa5-a161-568738416ee7', '90811bb3-64b0-4d6f-9c51-9d3fdd8985ef', '5ea2aef1-8bd1-43eb-b2cf-df46b8dfa8a8', '6c892790-1128-42f4-b594-2dca2e1ce329', 'dad2276e-8211-4fd7-9990-37db739d9767', '5475b80b-78f3-4592-851e-4240db3b384a', 'd044f251-f8df-4358-bbfc-c8732404b34a', 'be107299-4012-4b38-b815-c2ee9e51456d', '6018e13e-928a-401f-aa5b-6a0a5f6fee99', '463b052b-ffbc-4f2c-8d1a-061c8f64cb12', 'c600c56b-610b-4094-81f8-854da471d3d1', '47f353d9-429b-45fb-8470-6e22878b413d', '2d4e3425-7547-4801-a02c-26c737980a1b', '530cced3-323b-4b2f-a8d3-127f69922470', 'df4937e3-52c3-4909-8aea-ad6167c0d72d'],
            4: ['77990573-b3b1-4e27-a98a-010dd9d3fbf8', 'eb255c43-3401-495a-a439-295962f09714', '524dbf58-e15b-4efb-9869-0d5fb38eb71d', '26f60d61-7a0f-4a94-89b7-77a8485bcf3c', '6eac3bac-ae1e-4285-aad2-3096d55eeaac', '09e3a6fa-8e74-4351-8698-0c7885e29829', '81a0aff5-7ccf-4740-8075-c100496d9ebd', '9dceb2c0-5086-4b5e-9869-a33bb5205359', '9501df06-0301-4f7b-b8de-06a8ffb02917', '9ecc8c61-b906-4bca-80e7-a2650605bda7', '95d8b874-b980-4fe6-b431-94825a8a2315', '10ec7bbe-41b0-47c7-9ea9-7be6e57c4664', '404e7cf5-105f-4993-80a1-1d8ecd279a53', 'd245c239-0eee-47a2-bff4-9b80c3b63284', '86d4be5b-a22d-4f3d-a2be-deb1a9a38994', '8e339243-d85b-4555-8ede-8a6bd6547e33', '3fb57d2a-1e7a-47da-a2b8-8125cd811a5c', 'b19b63c8-63ff-4212-a90e-271ce164e8e9', '833fa78c-9b76-40ab-a73c-15d7ae950606', 'dea6cfd2-5fb8-449c-b5c9-177d240f87eb', 'a8827370-7ce3-4d62-99d3-e144875dc127', 'a4d340ca-3426-4a51-8e0d-768f2caca036', 'ca16959b-7373-47fd-a348-89dbcfb3ae04', 'c7292cb2-294b-4a01-bd94-7350faf9beab', '4e855906-9d35-4bc9-bf63-28027a0ae5a7', 'd82260f5-2f17-4e36-b6f2-c50d2d942b6c', '8eea660c-7786-46eb-91cd-ab650dcf6af9', '1d3675c8-b286-453c-96e1-90c0da25a811', '8c50111e-15d9-45fe-85ca-4e84492d05f3', '8f6ce499-3e8d-4de0-b22c-2c10152f7035', '7ca49c58-aea9-4aab-bc0f-c50bb019d441', '39ece60e-48ce-425c-8c21-d0a86e58ce30', '64343f52-61b1-4b1c-b565-1250b0493c79', '8da74897-0b70-4ad7-afce-cd061159b414', '82d00655-86e0-4b6d-9a95-d31fbf82425d', 'e635a861-7468-4fd1-b0e1-a6c89a166a46', '2478d1d4-ec0c-4c56-ac2b-8b00c37e829d', '1d8e5a39-d197-4f35-b6a6-5a99d0319cdf', 'df0618bb-121a-47f8-9123-e9254e4220a9'],
            5: ['82c78e26-816d-469a-8e7f-a5ae09441d48'],
            6: ['f7eceb52-d604-44d2-8a29-8bf33c5bfa96', 'ec346c7d-b8b2-44c9-b922-4c625561c20f', '83b68eb2-d679-42f2-b2d5-99276eb50d7e', '03e6b0d2-76c4-4619-ad58-e6fc06313cc8', 'dac2eb79-5978-4e31-a425-05b0d57d46f2', '2a80bb18-a9c2-4158-b902-1bfbe2560ab3'],
            -2: ['9bbdaf27-8066-4d84-b388-633a7f43bf62', '49953288-8047-4962-a14c-00b0bb3de095', 'eb8e0cfd-f2d2-48cd-ac26-aad9a8d4f8cd', 'd3ad770c-b885-4db4-ad44-5eafe805278c']
        },
        'Clothes Dryer': {
            1: ['6810e325-6c83-46d2-904e-0679d8936201', '73a58748-b4f6-4723-a385-f99b4a9177f8', '1f52db2b-07e1-4079-9476-78aa22a1ab36', '454c08ba-58c1-46ae-b5a3-481c99f5bef9'],
            2: ['fb15ed5e-4e01-40bf-b130-86844a214c62', '982bc881-87d3-4f7c-9642-e738109f4c1a', 'ceb594fb-5b1a-4fa4-b833-c93f64bb489e'],
            5: ['924291d6-cb2a-4411-9155-b801704925a0', '1d5f7424-5f98-4967-b765-5f1c215f582e', '0ded029b-b8b2-4bf1-aacc-7fbcd4db9405', 'd22e372c-1665-47c8-8fc7-6259c14642f0', '80634224-cafe-413b-8496-9968c8d9f542', 'ae9736a2-b212-4d91-b767-b624d127d849'],
            -2: ['f632b16e-4c2a-4d1f-8d52-85917acc52c6']

        },
        'Cooking Range': {
            1: ['3afc7a80-5978-4e5b-929c-29d9520b228a', '5b7ec7fa-a583-4224-8f8e-5825bc9b2691', 'e9f4f8b7-ff68-4bc8-b233-2a1959bd817f'],
            2: ['65ee0c7d-4103-48a5-b56f-4b7ccbe92045', '3b457c20-896f-4c83-823d-a11dfdb5eebb', '55e7fa7d-c611-4dca-8581-deccd4fb0614'],
            5: ['271eb59e-bc8e-4129-bbbb-c71929075f06', '032f5627-5673-456f-a461-2bd171464510', '2e33b3c8-b953-4691-8d9b-43ea3dfea316', '31b85de0-c47a-4537-b4d8-6b32a357ab13'],
            -2: ['8ed8c6b0-41e7-4829-bf1f-bddccb46f75d']
        }
    }

    if not os.path.exists('options.txt'):
        options = {}
        full_options = OutputArchetypeVariantOptionDiff
            [OutputArchetypeVariantOptionDiff['OutputArchetypeVariantID' ]= =1]
        options[1] = dict(zip(full_options['CategoryID'].values, full_options['OptionGUID'].values))
        for id in range(2, len(list(set(OutputArchetypeVariantOptionDiff['OutputArchetypeVariantID'].values)) ) +1):
            # for id in range(2, 5):
            print id
            part_options = OutputArchetypeVariantOptionDiff
                [OutputArchetypeVariantOptionDiff['OutputArchetypeVariantID' ]= =id]
            options[id] = dict(zip(part_options['CategoryID'].values, part_options['OptionGUID'].values))
            for k, v in options[1].iteritems():
                if not k in options[id].keys():
                    options[id][k] = v

        # f = open('output.txt', 'w')
        # f.write(str(options))
    else:
        s = open('options.txt', 'r').read()
        options = eval(s)

    for category in ['Cooling System', 'Heating System', 'Windows', 'Water Heater', 'Clothes Dryer', 'Cooking Range']:
        print category
        df = revise_variant_ids(df, category, guid_dict[category], con, options)

    df.to_csv('recs_revised.csv', index=False)

def revise_variant_ids(df, category, guid_dict, con, options):

    def remove_variants(row, col, guid_dict, output_archetype_variant_ids, options):

        print col, row.name

        if pd.isnull(output_archetype_variant_ids):
            return np.nan

        guids_to_keep = []
        for k, v in guid_dict.items():
            if k == row[col]:
                guids_to_keep += v

        variants_to_keep = []
        for id in output_archetype_variant_ids.split(';'):
            if int(id) in options.keys():
                if bool(set(guids_to_keep) & set(options[int(id)].values())):
                    variants_to_keep.append(id)

        if variants_to_keep:
            return ';'.join([str(x) for x in variants_to_keep])
        else:
            return np.nan

    if category == 'Windows':
        col = 'typeglass'
    elif category == 'Water Heater':
        col = 'fuelh2o'
    elif category == 'Cooling System':
        col = 'cooltype'
    elif category == 'Heating System':
        col = 'equipm'
    elif category == 'Clothes Dryer':
        col = 'dryrfuel'
    elif category == 'Cooking Range':
        col = 'stovenfuel'

    df['OutputArchetypeVariantID (Meta Parameters + Heating + Cooling + WH + Windows + CD + CR)'] = df.apply \
        (lambda x: remove_variants(x, col, guid_dict, x
            ['OutputArchetypeVariantID (Meta Parameters + Heating + Cooling + WH + Windows + CD + CR)'], options), axis=1)

    return df

def assign_epw_stations(df):

    epw = pd.read_csv('RECS_EPW_matches.csv')
        [['DOEID', 'TMY3_ID', 'ProvState', 'Station', 'HDD65_Annual', 'CDD65_Annual']]
    df = pd.merge(df, epw, left_on='doeid', right_on='DOEID')
    del df['DOEID']

    return df

def assign_location(df): # Location

    # def epw(tmy3_id):
    # for EPW in EPWs:
    # if str(tmy3_id) in str(EPW):
    # return EPW

    # df['Location'] = df['TMY3_ID'].apply(lambda x: epw(x))

    rd_map = {1: ['CT', 'ME', 'NH', 'RI', 'VT'],
              2: ['MA'],
              3: ['NY'],
              4: ['NJ'],
              5: ['PA'],
              6: ['IL'],
              7: ['IN', 'OH'],
              8: ['MI'],
              9: ['WI'],
              10: ['IA', 'MN', 'ND', 'SD'],
              11: ['KS', 'NE'],
              12: ['MO'],
              13: ['VA'],
              14: ['DE', 'DC', 'MD', 'WV'],
              15: ['GA'],
              16: ['NC', 'SC'],
              17: ['FL'],
              18: ['AL', 'KY', 'MS'],
              19: ['TN'],
              20: ['AR', 'LA', 'OK'],
              21: ['TX'],
              22: ['CO'],
              23: ['ID', 'MT', 'UT', 'WY'],
              24: ['AZ'],
              25: ['NV', 'NM'],
              26: ['CA'],
              27: ['AK', 'HI', 'OR', 'WA']}

    def epw(rd):
        states = rd_map[rd]
        epws = []
        for EPW in EPWs:
            state = EPW.split('_')[1]
            if state in states:
                epws.append(EPW)
        return ';'.join([str(x) for x in epws])

    df['Location'] = df['reportable_domain'].apply(lambda x: epw(x))

    return df

def assign_vintage(df): # Vintage

    vintages = {1: 'pre-1950',
                2: '1950s',
                3: '1960s',
                4: '1970s',
                5: '1980s',
                6: '1990s',
                7: '2000s',
                8: '2000s'}

    df['Vintage'] = df['yearmaderange'].apply(lambda x: vintages[x])

    return df

def assign_heating_fuel(df): # Heating fuel

    fuels = {1 :'Natural Gas',
             2 :'Propane/LPG',
             3 :'Fuel Oil',
             5 :'Electricity',
             4 :'Other Fuel',
             7 :'Other Fuel',
             8 :'Other Fuel',
             9 :'Other Fuel',
             21 :'Other Fuel',
             -2 :'None'}

    df['Heating Fuel'] = df['fuelheat'].apply(lambda x: fuels[x])

    return df

def assign_size(df): # Floor area

    df['Intsize'] = df[['tothsqft', 'totcsqft']].max(axis=1)
    df.loc[:, 'Size'] = 0
    df.loc[(df['Intsize'] < 1500), 'Size'] = '0-1499'
    df.loc[(df['Intsize'] >= 1500) & (df['Intsize'] < 2500), 'Size'] = '1500-2499'
    df.loc[(df['Intsize'] >= 2500) & (df['Intsize'] < 3500), 'Size'] = '2500-3499'
    df.loc[(df['Intsize'] >= 3500) & (df['Intsize'] < 4500), 'Size'] = '3500-4499'
    df.loc[(df['Intsize'] >= 4500), 'Size'] = '4500+'

    del df['Intsize']

    return df

def assign_stories(df): # Number of stories

    stories = {10: '1',
               20: '2',
               31: '3+',
               32: '3+',
               40: '1;2;3+',
               50: '1;2;3+',
               -2: '1;2;3+'}

    df['Stories'] = df['stories'].apply(lambda x: stories[x])

    return df

def assign_foundation_type(df):

    def assign_foundation(crawl, cellar, concrete, baseheat):

        foundations = []
        if crawl == 1:
            foundations.append('Crawl')
        if concrete == 1:
            foundations.append('Slab')
        if cellar == 1 and baseheat == 1:
            foundations.append('Heated Basement')
        if cellar == 1 and baseheat == 0:
            foundations.append('Unheated Basement')
        if len(foundations) == 0:
            foundations.append('None')

        return ';'.join([str(x) for x in foundations])

    # df['Foundation Type'] = df.apply(lambda x: assign_foundation(x['crawl'], x['cellar'], x['concrete'], x['baseheat']), axis=1)
    df['Foundation Type'] = 'None;Unheated Basement;Heated Basement;Crawl;Slab'

    return df

def assign_daytime_occupancy(df):

    df['Daytime Occupancy'] = 'No;Yes;Average'

    return df

def assign_usage_level(df): # Usage level

    df['Usage Level'] = 'Low;Medium;High;Average'

    return df

def assign_attached_garage(df): # Attached garage

    garage = {1: 'No;Yes',
              2: 'No;Yes',
              3: 'No;Yes',
              -2: 'No;Yes'}

    df['Attached Garage'] = df['sizeofgarage'].apply(lambda x: garage[x])

    return df

def assign_heating_setpoint(df): # Heating set points

    def htgstpt(stpt):
        if stpt > 0 and stpt < 65.5:
            return Option[Option['OptionName' ]= ='63 F']['OptionGUID'].values[0]
        elif stpt >= 65.5 and stpt < 69.5:
            return Option[Option['OptionName' ]= ='68 F']['OptionGUID'].values[0]
        elif stpt >= 69.5 and stpt < 72.0:
            return Option[Option['OptionName' ]= ='71 F']['OptionGUID'].values[0]
        elif stpt >= 72.0:
            return Option[Option['OptionName' ]= ='73 F']['OptionGUID'].values[0]
        else:
            return np.nan

    df['Heating Set Point'] = df['temphome'].apply(lambda x: htgstpt(x))

    return df

def assign_cooling_setpoint(df): # Cooling set points

    def clgstpt(stpt):
        if stpt > 0 and stpt < 71.5:
            return Option[Option['OptionName' ]= ='69 F']['OptionGUID'].values[0]
        elif stpt >= 71.5 and stpt < 75.0:
            return Option[Option['OptionName' ]= ='74 F']['OptionGUID'].values[0]
        elif stpt >= 75.0 and stpt < 77.0:
            return Option[Option['OptionName' ]= ='76 F']['OptionGUID'].values[0]
        elif stpt >= 77.0:
            return Option[Option['OptionName' ]= ='78 F']['OptionGUID'].values[0]
        else:
            return np.nan

    df['Cooling Set Point'] = df['temphomeac'].apply(lambda x: clgstpt(x))

    return df

def assign_option_guids(df, option):

    def iter(row, category_id, meta_category_dependency_ids):

        IDs = {}
        for meta_category_dependency_id in meta_category_dependency_ids:

            meta_option = MetaOption[(MetaOption['MetaCategoryID' ]= =meta_category_dependency_id) &
                        (MetaOption['Name'] == row[
                    MetaCategory[MetaCategory['ID'] == meta_category_dependency_id]['Name'].values[0]])]

            IDs['MetaOptionIDForMetaCategoryID{}'.format(meta_category_dependency_id)] = [meta_option['ID'].values[0]]

        meta_option_combo = MetaOptionCombo

        for i in range(1, 10):
            if 'MetaOptionIDForMetaCategoryID{}'.format(i) in IDs.keys():
                meta_option_combo = meta_option_combo[
                    meta_option_combo['MetaOptionIDForMetaCategoryID{}'.format(i)] == IDs[
                        'MetaOptionIDForMetaCategoryID{}'.format(i)]]
            else:
                meta_option_combo = meta_option_combo[
                    pd.isnull(meta_option_combo['MetaOptionIDForMetaCategoryID{}'.format(i)])]

        meta_option_combo_id = meta_option_combo['ID'].values[0]

        beopt_weighting_factor = BEoptWeightingFactor[BEoptWeightingFactor['MetaOptionComboID'] == meta_option_combo_id]
        beopt_weighting_factor = beopt_weighting_factor[beopt_weighting_factor['CategoryID'] == category_id]

        beopt_weighting_factor = beopt_weighting_factor[
            beopt_weighting_factor['Value'] > 0.0001]  # don't include the options that aren't sampled

        return ';'.join([str(x) for x in beopt_weighting_factor['OptionGUID'].values])

    category_id = Category[Category['CategoryName'] == option]['CategoryID'].values[0]

    meta_category_dependency_ids = BEoptCategoryDependency[BEoptCategoryDependency['CategoryID'] == category_id][
        'MetaCategoryDependencyID']

    df[option] = df.apply(lambda x: iter(x, category_id, meta_category_dependency_ids), axis=1)

    return df


def assign_variant_ids(df):
    def iter(row, meta_category_dependency_ids):

        IDs = {}
        for meta_category_dependency_id in meta_category_dependency_ids:

            params = []
            for param in row[MetaCategory[MetaCategory['ID'] == meta_category_dependency_id]['Name']].values[0].split(
                    ';'):
                params.append(param)

            meta_option = MetaOption[
                (MetaOption['MetaCategoryID'] == meta_category_dependency_id) & (MetaOption['Name'].isin(params))]

            IDs['MetaOptionIDForMetaCategoryID{}'.format(meta_category_dependency_id)] = meta_option['ID'].tolist()

        output_archetype_variant = OutputArchetypeVariant

        for i in meta_category_dependency_ids:
            output_archetype_variant = output_archetype_variant[
                output_archetype_variant['MetaOptionIDForMetaCategoryID{}'.format(i)].isin(
                    IDs['MetaOptionIDForMetaCategoryID{}'.format(i)])]

        return ';'.join([str(x) for x in output_archetype_variant['ID'].values])

    meta_category_dependency_ids = range(1, 10)

    df['OutputArchetypeVariantID (Meta Parameters)'] = df.apply(lambda x: iter(x, meta_category_dependency_ids), axis=1)

    return df


def retrieve_data():
    if not os.path.exists('eia.recs_2009_microdata.pkl'):
        con_string = "host = gispgdb.nrel.gov port = 5432 dbname = dav-gis user = jalley password = jalley"
        con = con = pg.connect(con_string)
        sql = """SELECT * FROM eia.recs_2009_microdata;"""
        df = pd.read_sql(sql, con)
        df.to_pickle('eia.recs_2009_microdata.pkl')
    df = pd.read_pickle('eia.recs_2009_microdata.pkl')

    return df


def regenerate():
    # Use this to regenerate processed data if changes are made to any of the classes below
    df = retrieve_data()
    df.to_pickle('processed_eia.recs_2009_microdata.pkl')
    return df


if __name__ == '__main__':
    # Choose regerate if you want to redo the processed pkl file, otherwise comment out
    df = regenerate()

    df = pd.read_pickle('processed_eia.recs_2009_microdata.pkl')
    main(df)
