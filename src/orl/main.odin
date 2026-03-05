package orl

import "src"


Url :: src.Url
Query_Param :: src.Query_Param

to_string :: proc {
	src.url_to_string,
	src.query_params_to_string,
}

parse_query_params :: src.parse_query_params
parse_url :: src.parse_url

get :: src.get
get_all :: src.get_all
append :: src.append_param
