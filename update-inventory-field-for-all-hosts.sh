curl -s http://127.0.0.1/api_jsonrpc.php \
--request POST \
--header 'Content-Type: application/json' \
-H 'cache-control: no-cache' \
-d '

{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": [
            "host"
        ],
        "selectInventory": [
            "url_c"
        ],
        "searchInventory": {
            "url_c": ""
        }
    },
    "id": 2,
    "auth": "b42c98b44f748dd82e2debf7fa2be02e"
}

' | \

jq -r .result[].hostid | \

sed "s%^%{\"hostid\":\"%g" | \

sed "s%$%\"},%g" | \

tr -cd "[:print:]" | \

sed "s%^%{\"jsonrpc\":\"2.0\",\"method\":\"host.massupdate\",\"params\":{\"hosts\":\[%" | \

sed "s%.$%\],\"inventory_mode\":1,\"inventory\":{\"url_c\":\"http:\/\/distrowatch.com\/\"}},\"auth\":\"b42c98b44f748dd82e2debf7fa2be02e\",\"id\":1}%" | \

xargs -i -0 echo "http://127.0.0.1/api_jsonrpc.php --request POST --header 'Content-Type: application/json' -H 'cache-control: no-cache' -d '{}'" | xargs curl
