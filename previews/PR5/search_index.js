var documenterSearchIndex = {"docs":
[{"location":"#OpenML.jl-Documentation","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"","category":"section"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"This is the reference documentation of OpenML.jl.","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"The OpenML platform provides an integration platform for carrying out and comparing machine learning solutions across a broad collection of public datasets and software platforms.","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Summary of OpenML.jl functionality:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"OpenML.list_tags(): for listing all dataset tags\nOpenML.list_datasets(; tag=nothing, filter=nothing, output_format=...): for listing available datasets\nOpenML.describe_dataset(id): to describe a particular dataset\nOpenML.load(id; parser=:arff): to download a dataset","category":"page"},{"location":"#Installation","page":"OpenML.jl Documentation","title":"Installation","text":"","category":"section"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"using Pkg\nPkg.add(\"OpenML\")","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"If running the demonstration below:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Pkg.add(\"DataFrames\") \nPkg.add(\"ScientificTypes\")","category":"page"},{"location":"#Sample-usage","page":"OpenML.jl Documentation","title":"Sample usage","text":"","category":"section"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"using OpenML # or using MLJ\nusing DataFrames\n\nOpenML.list_tags()","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Listing all datasets with the \"OpenML100\" tag which also have n instances and p features, where 100 < n < 1000 and 1 < p < 10:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"ds = OpenML.list_datasets(\n          tag = \"OpenML100\",\n          filter = \"number_instances/100..1000/number_features/1..10\",\n          output_format = DataFrame)","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Describing and loading one of these datasets:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"OpenML.describe_dataset(15)\ntable = OpenML.load(15)","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Converting to a data frame:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"df = DataFrame(table)","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"Inspecting it's schema:","category":"page"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"using ScientificTypes\nschema(table)","category":"page"},{"location":"#Public-API","page":"OpenML.jl Documentation","title":"Public API","text":"","category":"section"},{"location":"","page":"OpenML.jl Documentation","title":"OpenML.jl Documentation","text":"OpenML.list_tags\nOpenML.list_datasets\nOpenML.describe_dataset\nOpenML.load","category":"page"},{"location":"#OpenML.list_tags","page":"OpenML.jl Documentation","title":"OpenML.list_tags","text":"list_tags()\n\nList all available tags.\n\n\n\n\n\n","category":"function"},{"location":"#OpenML.list_datasets","page":"OpenML.jl Documentation","title":"OpenML.list_datasets","text":"list_datasets(; tag = nothing, filters = \"\" api_key = \"\", output_format = NamedTuple)\n\nLists all active OpenML datasets, if tag = nothing (default). To list only datasets with a given tag, choose one of the tags in list_tags(). An alternative output_format can be chosen, e.g. DataFrame, if the DataFrames package is loaded.\n\nA filter is a string of <data quality>/<range> or <data quality>/<value> pairs, concatenated using /, such as\n\n    filter = \"number_features/10/number_instances/500..10000\"\n\nThe allowed data qualities include tag, status, limit, offset, data_id, data_name, data_version, uploader, number_instances, number_features, number_classes, number_missing_values.\n\nFor more on the format and effect of filters refer to the openml API.\n\nExamples\n\njulia> using DataFrames\n\njulia> ds = OpenML.list_datasets(\n               tag = \"OpenML100\",\n               filter = \"number_instances/100..1000/number_features/1..10\",\n               output_format = DataFrame\n)\n\njulia> sort!(ds, :NumberOfFeatures)\n\n\n\n\n\n","category":"function"},{"location":"#OpenML.describe_dataset","page":"OpenML.jl Documentation","title":"OpenML.describe_dataset","text":"describe_dataset(id)\n\nLoad and show the OpenML description of the data set id. Use list_datasets to browse available data sets.\n\nExamples\n\njulia> OpenML.describe_dataset(6)\n  Author: David J. Slate Source: UCI\n  (https://archive.ics.uci.edu/ml/datasets/Letter+Recognition) - 01-01-1991 Please cite: P.\n  W. Frey and D. J. Slate. \"Letter Recognition Using Holland-style Adaptive Classifiers\".\n  Machine Learning 6(2), 1991\n\n    1. TITLE:\n\n  Letter Image Recognition Data\n\n  The objective is to identify each of a large number of black-and-white\n  rectangular pixel displays as one of the 26 capital letters in the English\n  alphabet.  The character images were based on 20 different fonts and each\n  letter within these 20 fonts was randomly distorted to produce a file of\n  20,000 unique stimuli.  Each stimulus was converted into 16 primitive\n  numerical attributes (statistical moments and edge counts) which were then\n  scaled to fit into a range of integer values from 0 through 15.  We\n  typically train on the first 16000 items and then use the resulting model\n  to predict the letter category for the remaining 4000.  See the article\n  cited above for more details.\n\n\n\n\n\n","category":"function"},{"location":"#OpenML.load","page":"OpenML.jl Documentation","title":"OpenML.load","text":"OpenML.load(id; parser = :arff)\n\nLoad the OpenML dataset with specified id, from those listed by list_datasets or on the OpenML site. With parser = :arff (default) the ARFFFiles.jl parser is used. With parser = :auto the output of the ARFFFiles parser is coerced to automatically detected scientific types.\n\nReturns a table.\n\nExamples\n\nusing DataFrames\ntable = OpenML.load(61);\ndf = DataFrame(table);\n\n\n\n\n\n","category":"function"}]
}
