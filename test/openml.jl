module TestOpenml

using Test
using HTTP
using MLJOpenML
import Tables.istable

response_test = MLJOpenML.load_Dataset_Description(61)
ntp_test = MLJOpenML.load(61)
@test istable(ntp_test)
dqlist_test = MLJOpenML.load_Data_Qualities_List()
data_features_test = MLJOpenML.load_Data_Features(61)
data_qualities_test = MLJOpenML.load_Data_Qualities(61)
limit = 5
offset = 8
filters_test = MLJOpenML.load_List_And_Filter("limit/$limit/offset/$offset")

@testset "HTTP connection" begin
    @test typeof(response_test) <: Dict
    @test response_test["data_set_description"]["name"] == "iris"
    @test response_test["data_set_description"]["format"] == "ARFF"
end

@testset "ARFF file conversion to NamedTuples" begin
    @test isempty(ntp_test) == false
    @test length(ntp_test[1]) == 150
    @test length(ntp_test) == 5
end

@testset "data api functions" begin
    @test typeof(dqlist_test["data_qualities_list"]) <: Dict

    @test typeof(data_features_test) <: Dict
    @test length(data_features_test["data_features"]["feature"]) == 5
    @test data_features_test["data_features"]["feature"][1]["name"] == "sepallength"

    @test typeof(data_qualities_test) <: Dict

    @test length(filters_test["data"]["dataset"]) == limit
    @test length(filters_test["data"]["dataset"][1]) == offset
end

end
true
