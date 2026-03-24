cetus aggregator skills

1. 调用cetus aggregator find router v3 api 获取报价。


# Authentication or restricts

# Aggregator V3

## 1. Find aggregator router swap result.

## Interface

**`GET** https://api-sui.cetus.zone/router_v3/find_routes`

## Query Params

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| from | string | yes | The from coin type. |
| target | string | yes | The target coin type. |
| amount | number | yes | When by_amount_in equals true, it means input amount, otherwise it means output amount. |
| by_amount_in | string | no | Fix input amount or fix output amount. We recommend just use by_amount_in equals true, if set by_amount_in equals false, it will just use CETUS provider. |
| split_count | number | no | When setting the split_count parameter to 1, the order will remain intact without any splitting. Setting a value greater than 1 will automatically divide the order into multiple parts accordingly. Please note that the maximum allowable value for split_count is 50, and default split_count is 50. |
| providers | string | no | We currently support 23 different providers: CETUS, SCALLOP, AFTERMATH, FLOWXV3, AFSUI, VOLO, KRIYAV3, KRIYA, ALPHAFI, FLOWX, BLUEMOVE, DEEPBOOKV3, BLUEFIN, HAEDAL, TURBOS, SPRINGSUI, STEAMM, METASTABLE, HAWAL, OBRIC, STEAMM_OMM_V2, STEAMM_OMM, and MOMENTUM.
If you don't specify any providers, the system will automatically utilize all the latest providers by default. To select specific providers, simply list them separated by commas (e.g., CETUS,DEEPBOOKV3).” |
| depth/max_depth | number | no | Now max depths support betweent 1 and 3, default setting is 3, it means you can get 3 hops paths.  |
| gas | number | no | The estimated gas amount is provided as follows: if the integrator pass a gas value, the response will default to that value. If no value is provided, the response will return a preset default value. Both input and output parameters are processed after decimal adjustment. For example, a value of 35000 represents 0.000035 SUI. |

Note: For cases without special requirements, you only need to set the first four parameters; the rest can use the default values.


### Now default support providers:
CETUS, SCALLOP, AFTERMATH, FLOWXV3, AFSUI, VOLO, KRIYAV3, KRIYA, ALPHAFI, FLOWX, BLUEMOVE, DEEPBOOKV3, BLUEFIN, HAEDAL, TURBOS, SPRINGSUI, STEAMM, METASTABLE, HAWAL, OBRIC, STEAMM_OMM_V2, STEAMM_OMM, and MOMENTUM,MAGMA,FERRADLMM,FERRACLMM,HAEDALPMM,HAEDALHMMV2


## Example

```bash
curl --location --request GET 'https://api-sui.cetus.zone/router_v3/find_routes?target=0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS&amount=4000000&from=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&v=1999999'
```

## Response data

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| » code | integer | true | none |
| » msg | string | true | none |

| Status code | Reason |
| --- | --- |
| 200 | OK |
| 4000 | Bad Request |
| 4030 | For bidden |
| 5000 | Liquidity is not enough |
| 5040 | Unsupport API Version |
| 400 | Unknow error |

## Response example

- Get router result success(200 Response)

```json
{
    "code": 200,
    "msg": "Success",
    "data": {
        "request_id": "fc59359262f4a7013e09625ed02d8468",
        "amount_in": 10000000,
        "amount_out": 4296,
        "deviation_ratio": "0.07938901",
        "paths": [
            {
                "id": "0xe7f40844d329124a12fe0e4997b5007b641734b47ce2e8e0eac6fe09d557954e",
                "provider": "MAGMA",
                "from": "0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL",
                "target": "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
                "direction": true,
                "fee_rate": "0.0001",
                "lot_size": 1,
                "amount_in": 10000000,
                "amount_out": 1169612,
                "published_at": "0x9a8e367ae1120a462af2144159a01ee71185b13d3a80d827022aa34ddcc7afcb",
                "extended_details": {
                    "after_sqrt_price": 6309028175088270238
                }
            },
            {
                "id": "0x9a1a135398d7d79cfdd27ed664b53afb4744faccb16d03dc7935c00619599f63",
                "provider": "CETUS",
                "from": "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
                "target": "0x93a3b2cdf609169baa2df5e746f5b45ae0a64242f46fa7b4c7a66527d0e328c9::susdt::SUSDT",
                "direction": false,
                "fee_rate": "0.01",
                "lot_size": 1,
                "amount_in": 1169612,
                "amount_out": 13781769856,
                "published_at": "0x550dcd6070230d8bf18d99d34e3b2ca1d3657b76cc80ffdacdb2b5d28d7e0124",
                "extended_details": {
                    "after_sqrt_price": 169233527930194888
                }
            },
            {
                "id": "0x2bcfb471c4f27539083c2c1ca0e0479ffd7ef544f2a7ec80ade7e7446faecf98",
                "provider": "CETUS",
                "from": "0x93a3b2cdf609169baa2df5e746f5b45ae0a64242f46fa7b4c7a66527d0e328c9::susdt::SUSDT",
                "target": "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
                "direction": false,
                "fee_rate": "0.01",
                "lot_size": 1,
                "amount_in": 13781769856,
                "amount_out": 4296,
                "published_at": "0x550dcd6070230d8bf18d99d34e3b2ca1d3657b76cc80ffdacdb2b5d28d7e0124",
                "extended_details": {
                    "after_sqrt_price": 33091158768251823095188
                }
            }
        ],
        "packages": {
            "aggregator_v3": "0x07c27e879ba9282506284b0fef26d393978906fc9496550d978c6f493dbfa3e5"
        },
        "gas": 35000
    }
}
```

- Get router result error (status code 400 Insufficient Liquidity)

```json
{
    "code": 400,
    "msg": "liquidity is not enough"
}
```

## Data schame

```json
{
  "code": 0,
  "msg": "string",
  "data": {
    "request_id": string,
    "gas": number,
    "amount_in": number,
    "amount_out": number,
    "deviation_ratio": string,
    "paths": [
      {
        "id": string,
        "provider": string,
        "from": string,
        "target": string,
        "direction": bool,
        "fee_rate": number,
        "lot_size": number,
        "amount_in": number,
        "amount_out": number,
        "published_at": string,
        "extended_details": {
					...
        }
      }
    ],
		"packages": {
      "aggregator_v3": string
    }
  }
}
```

## Feature

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| code | integer | true | http code |
| msg | string | true | error msg |
| data | object | false | none |
| » gas | integer | true | the estimated gas amount |
| » amount_in | integer | true | total input amount of all routes |
| » amount_out | integer | true | total output amount of all routes |
| » routes | [object] | true | finded route |
| » request_id | string | true | To index the path information returned from this request, you can pass the request ID to the swap interface to retrieve previously cached results, thereby avoiding the need to repeatedly input large and complex path information. |
| »» path | [object] | true | none |
| »»» id | string | true | The object id of this pool. |
| »»» provider | string | true | The platform type of this path. |
| »»» from | string | true | The from coin type. |
| »»» target | string | true | The target coin type. |
| »»» direction | boolean | true | The direction of pool. |
| »»» fee_rate | string | true | The fee rate of this pool. |
| »»» lot_size | integer | true | The lot_size of this pool. |
| »»» amount_in | integer | true | The input amount of this path. |
| »»» amount_out | integer | true | The output amount of this path. |
| »»» extended_details | object | false | The extended details of this pool, like turbos fee type or aftermath lp supply type. |
| »» amount_in | integer | true | The input amount of this route, include multi hops. |
| »» amount_out | integer | true | The output amount of this route, include multi hops. |
| »» initial_price | string | true | The initial price of this route. |

## 2. Build swapv3 tx

## Interface

`POST *https://api-sui-mcp.cetus.zone/aggregator/swap_v3*`


## Query Params

| Name | Location | Type | Required | Description |
| --- | --- | --- | --- | --- |
| apikey | query | string | yes | <please connection to cetus manager> |

## Body Params

| Name | Location | Type | Required | Description |
| --- | --- | --- | --- | --- |
| request_id | query | string | yes | The request_id returned by find routes interface. |
| wallet | query | string | yes | User sui wallet address. |
| slippage | query | number | yes | The slippage protection data, where 0.01 indicates that a slippage of 1% is acceptable. Tx will auto failed when swap result exceed this price slippage. |
| by_amount_in | query | string | no | Used to identify a fixed number of directions, it needs to match the data passed in find routes, with a default value of `true`. |
| partner | query | string | no | The object id of partner. The partner is a referral commission feature where partners holding a PartnerCap can earn a share of protocol fees from trades made by users through their channels.For partner fee collection methods, please refer to: https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-sdk-v2/sdk-modules/cetusprotocol-sui-clmm-sdk/partner-swap |

## Example

```bash
curl --location --request POST 'https://api-sui-mcp.cetus.zone/aggregator/swap?apikey=xxx' \
--header 'Content-Type: application/json' \
--data-raw '{
    "request_id": "9a0ea720-e79a-4f52-85a9-21cd20291dab",
    "wallet": "0x...",
    "slippage": 0.005
}'
```

## Response data

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| code | integer | true | status code |
| msg | string | true | none |
| data | string | true | none |
| » data | string | true | Bytes representing the transaction data.After signing, it can be submitted to the blockchain. |
| » to | string | true | Array of all used aggregator contracts, separated by commas. |

| Status code | Reason | Description |
| --- | --- | --- |
| 200 | OK | Succeed |
| 400 | Bad Request |  |

## Response example

- Get router result success(200 Response)

```bash
{
    "code": 200,
    "msg": "Success",
    "data": {
        "data": "AAAHAQCJabZsKnIcXqghVCVOnYLLfey96rBf2+SnwVKzMgNBtJipDxkAAAAAIDFsMnhyVafpu1B1vc+TKOyIhecwHvfAl1FHtq7yewDTAAiAlpgAAAAAAAEBu4grVG1LFqoV3nNOoBwxK5K72hXPd3cSinIZVydWs7XWhswYAAAAAAEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAQAAAAAAAAAAAQHxzw6BBI3xaOvrG4Aw+tJLPgtTroJ8JQU//wd5wURbb4+8GAAAAAAAAAEBD292IRHXeLKmLJqje1j2EE4gA76KuxiLyECnkWmmEcmxwL0YAAAAAAEACCeKAAAAAAAABwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgRjb2luBXNwbGl0AQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAIBAAABAQACAwAAAAABAQEAAPmO0CmvVV5KED/r8mJD3DOsCafqGy2n5BTHKLJbcpCGBnR1cmJvcwhzd2FwX2IyYQMH/ba3F9XHXzhA0mkVZbDi8i2fkieDMl2cvdnZc48+iiYEY29pbgRDT0lOAAcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAeRv7w4akGvz9myUzBY1+kVodOCkInMJo/0Mz1U1jOcoQtmZWUxMDAwMGJwcwtGRUUxMDAwMEJQUwAEAQIAAwEAAAABAwABBAAA+Y7QKa9VXkoQP+vyYkPcM6wJp+obLafkFMcosltykIYGdHVyYm9zCHN3YXBfYTJiAwf9trcX1cdfOEDSaRVlsOLyLZ+SJ4MyXZy92dlzjz6KJgRjb2luBENPSU4AB11LMCUGZFw3/xM7mMS1ClrhSEFllzjW1zPVnQ0hepO/BGNvaW4EQ09JTgAHkb+8OGpBr8/ZslMwWNfpFaHTgpCJzCaP9DM9VNYznKELZmVlMTAwMDBicHMLRkVFMTAwMDBCUFMABAEFAAMCAAAAAQMAAQQAAPmO0CmvVV5KED/r8mJD3DOsCafqGy2n5BTHKLJbcpCGBXV0aWxzGHRyYW5zZmVyX29yX2Rlc3Ryb3lfY29pbgEHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQABAwAAAAAA+Y7QKa9VXkoQP+vyYkPcM6wJp+obLafkFMcosltykIYFdXRpbHMUY2hlY2tfY29pbl90aHJlc2hvbGQBB11LMCUGZFw3/xM7mMS1ClrhSEFllzjW1zPVnQ0hepO/BGNvaW4EQ09JTgACAwMAAAABBgAA+Y7QKa9VXkoQP+vyYkPcM6wJp+obLafkFMcosltykIYFdXRpbHMYdHJhbnNmZXJfb3JfZGVzdHJveV9jb2luAQddSzAlBmRcN/8TO5jEtQpa4UhBZZc41tcz1Z0NIXqTvwRjb2luBENPSU4AAQMDAAAApsj25wWEQuWgV3jUa3IcErW5MOCFlxfgXu0bJ1u6/C4BQw4CoILR6wX7JcSrvN1di+BT1K6jlnT3myT+vtmiggvDxw8ZAAAAACBc41UbrU4zM0qvuLWFOsQsnRi14dbf8+ps5MEGjavQsKbI9ucFhELloFd41GtyHBK1uTDghZcX4F7tGydbuvwu7gIAAAAAAACAqBIBAAAAAAA=",
        "to": "0xec2108d2092dd6f1f6fe45def639500e323596e0bab9fabc206461aadf357e6a,0xec2108d2092dd6f1f6fe45def639500e323596e0bab9fabc206461aadf357e6a"
    }
}
```
