//
//  Cloudflare.swift
//  Bonfire
//
//  Copyright © 2020 ipse. All rights reserved.
//
import Foundation
import Alamofire
import CoreData

struct Cloudflare {
    
    private let cfBaseURL = "https://api.cloudflare.com/client/v4/"
    public var isLoggedIn = false
    private var apiKey = ""
    private var apiEmail = ""
    init(email: String, apiKey: String) {
        // Check if there us a valid 'session' (coredata has a record of a login)
        // NOTE:
        //      CoreData will only ever have ONE record in the Account table.
        //      If a record exists, then a user has saved a 'session' thus us logged in.
        //      A 'session' will save the users login containing:
        //             - Their email address.
        //             - Their API key.
        //             - The selected Zone (selected at login or updated in settings)
        
        // Check if an account is already stored
        let account:Account? = self.getRegistedAccountDetails()

        self.apiKey = account!.apiKey ?? apiKey
        self.apiEmail = account!.email ?? email


        
    }
    public func getRegistedAccountDetails() -> Account? {
        
        // Get a reference to your App Delegate
        let appDelegate = AppDelegate.shared
        
        // Hold a reference to the managed context
        let managedContext = appDelegate.persistentContainer.viewContext
        
        do
        {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Account")
            fetchRequest.fetchLimit = 1
            
            let results = try managedContext.fetch(fetchRequest)
            let account = results as! [Account]
            if account.count > 0{
                return account[0]
            }else{
                return nil
            }
            
        }
        catch let error as NSError {
            print ("Could not fetch \(error) , \(error.userInfo )")
        }
        return nil
    }
    

    
    /**
     Make An API Request
     This method makes a request to the Cloudflare REST API.
     Parameters:
     - endpoint: The desired API endpoint (e.g. zones)
     - method: The HTTP method to use, generally .get or .post
     - showActInd: Boolean of if a spinner should be shown
     - completion: The code block to run once a response has been recieved (Recieves the parameter "response" as a Dictionary)
    **/
    public func makeRequest(endpoint: String, method: HTTPMethod, data: Parameters?, showActInd: Bool, completion: @escaping (_ response: Dictionary<String, Any>)->()) {
        // Show Activity Indicator
        let appDel = UIApplication.shared.delegate as! AppDelegate
        if showActInd {
            appDel.toggleActInd(on: true)
        }
        let headers = [
            "X-Auth-Key": self.apiKey,
            "X-Auth-Email": self.apiEmail,
            "Content-Type": "application/json"]
        Alamofire.request(URL(string: cfBaseURL + endpoint)!, method: method, parameters: data,encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            appDel.toggleActInd(on: false)
            switch response.result {
            case .success(_):
                if let resultDict = response.result.value as? Dictionary<String, Any> {
                    completion(resultDict)
                } else {
                    completion(["Error":"Unknown"])
                }
            case .failure(_):
                completion(["Error":"Unknown"])
            }
        }
    }
    
    public func makeRequest(endpoint: String, method: HTTPMethod, showActInd: Bool, completion: @escaping (_ response: Dictionary<String, Any>)->()) {
        self.makeRequest(endpoint: endpoint, method: method, data: nil, showActInd: showActInd, completion: completion)
    }
    
    /**
     Calls Clourflares's get zones API endpoint and returns a list of all zones
     API documentation:
     [GET zones](https://api.cloudflare.com/#zone-list-zones)
     
     - Returns: A dictionary containing relevant data points
     */
    public func getZones(completion: @escaping (_ zones: [Zone])->()) {
        var retVal: [Zone] = []
        self.makeRequest(endpoint: "zones", method: .get, showActInd: true, completion: { response in
            if let result: Array<Dictionary<String, Any>> = response["result"] as? Array<Dictionary<String, Any>> {
                for zone in result {
                    print("\(zone["name"])")
                    if let zname:String = zone["name"] as? String, let zid:String = zone["id"] as? String {
                        print("got name")
                        retVal.append(Zone(name: zname, id: zid))
                    }
                }
            }
            completion(retVal)
        })
        
//        let retVal: [Zone] = [
//            Zone(name: "example.com", id: "023e105f4ecef8ad9ca31a8372d0c353"),
//            Zone(name: "test.com", id: "353c0d2738a13ac9da8fece4f501e320"),
//            Zone(name: "a.site", id: "853e105f4ecef8ad9ca31a8372d0c432")
//        ]
    }
    
    /**
     Calls Clourflare's analytics API endpoint and returns certain data points
     
     API documentation:
     [GET zones/:zone_identifier/analytics/dashboard](https://api.cloudflare.com/#zone-analytics-dashboard)
     
     - Parameters:
     - zoneId: The id of the zone that you want analytics for

     - Returns: A dictionary containing relevant data points
     */
    public func getAnalytics(zoneId: String, completion: @escaping (_ data: [String: Any]?)->()) {
//        let data: Data = """
//            {
//              "success": true,
//              "errors": [],
//              "messages": [],
//              "result": {
//                "totals": {
//                  "since": "2015-01-01T12:23:00Z",
//                  "until": "2015-01-02T12:23:00Z",
//                  "requests": {
//                    "all": 2000,
//                    "cached": 750,
//                    "uncached": 1250,
//                    "content_type": {
//                      "css": 15343,
//                      "html": 1234213,
//                      "javascript": 318236,
//                      "gif": 23178,
//                      "jpeg": 1982048
//                    },
//                    "country": {
//                      "US": 4181364,
//                      "AU": 37298,
//                      "GB": 293846
//                    },
//                    "ssl": {
//                      "encrypted": 12978361,
//                      "unencrypted": 781263
//                    },
//                    "ssl_protocols": {
//                      "TLSv1": 398232,
//                      "TLSv1.1": 12532236,
//                      "TLSv1.2": 2447136,
//                      "TLSv1.3": 10483332,
//                      "none": 781263
//                    },
//                    "http_status": {
//                      "200": 13496983,
//                      "301": 283,
//                      "400": 187936,
//                      "402": 1828,
//                      "404": 1293
//                    }
//                  },
//                  "bandwidth": {
//                    "all": 213867451,
//                    "cached": 113205063,
//                    "uncached": 113205063,
//                    "content_type": {
//                      "css": 237421,
//                      "html": 1231290,
//                      "javascript": 123245,
//                      "gif": 1234242,
//                      "jpeg": 784278
//                    },
//                    "country": {
//                      "US": 123145433,
//                      "AG": 2342483,
//                      "GI": 984753
//                    },
//                    "ssl": {
//                      "encrypted": 37592942,
//                      "unencrypted": 237654192
//                    },
//                    "ssl_protocols": {
//                      "TLSv1": 398232,
//                      "TLSv1.1": 12532236,
//                      "TLSv1.2": 2447136,
//                      "TLSv1.3": 10483332,
//                      "none": 781263
//                    }
//                  },
//                  "threats": {
//                    "all": 23423873,
//                    "country": {
//                      "US": 123,
//                      "CN": 523423,
//                      "AU": 91
//                    },
//                    "type": {
//                      "user.ban.ip": 123,
//                      "hot.ban.unknown": 5324,
//                      "macro.chl.captchaErr": 1341,
//                      "macro.chl.jschlErr": 5323
//                    }
//                  },
//                  "pageviews": {
//                    "all": 5724723,
//                    "search_engine": {
//                      "googlebot": 35272,
//                      "pingdom": 13435,
//                      "bingbot": 5372,
//                      "baidubot": 1345
//                    }
//                  },
//                  "uniques": {
//                    "all": 12343
//                  }
//                },
//                "timeseries": [
//                  {
//                    "since": "2015-01-01T12:23:00Z",
//                    "until": "2015-01-02T12:23:00Z",
//                    "requests": {
//                      "all": 1234085328,
//                      "cached": 1234085328,
//                      "uncached": 13876154,
//                      "content_type": {
//                        "css": 15343,
//                        "html": 1234213,
//                        "javascript": 318236,
//                        "gif": 23178,
//                        "jpeg": 1982048
//                      },
//                      "country": {
//                        "US": 4181364,
//                        "AG": 37298,
//                        "GI": 293846
//                      },
//                      "ssl": {
//                        "encrypted": 12978361,
//                        "unencrypted": 781263
//                      },
//                      "ssl_protocols": {
//                        "TLSv1": 398232,
//                        "TLSv1.1": 12532236,
//                        "TLSv1.2": 2447136,
//                        "TLSv1.3": 10483332,
//                        "none": 781263
//                      },
//                      "http_status": {
//                        "200": 13496983,
//                        "301": 283,
//                        "400": 187936,
//                        "402": 1828,
//                        "404": 1293
//                      }
//                    },
//                    "bandwidth": {
//                      "all": 213867451,
//                      "cached": 113205063,
//                      "uncached": 113205063,
//                      "content_type": {
//                        "css": 237421,
//                        "html": 1231290,
//                        "javascript": 123245,
//                        "gif": 1234242,
//                        "jpeg": 784278
//                      },
//                      "country": {
//                        "US": 123145433,
//                        "AG": 2342483,
//                        "GI": 984753
//                      },
//                      "ssl": {
//                        "encrypted": 37592942,
//                        "unencrypted": 237654192
//                      },
//                      "ssl_protocols": {
//                        "TLSv1": 398232,
//                        "TLSv1.1": 12532236,
//                        "TLSv1.2": 2447136,
//                        "TLSv1.3": 10483332,
//                        "none": 781263
//                      }
//                    },
//                    "threats": {
//                      "all": 23423873,
//                      "country": {
//                        "US": 123,
//                        "CN": 523423,
//                        "AU": 91
//                      },
//                      "type": {
//                        "user.ban.ip": 123,
//                        "hot.ban.unknown": 5324,
//                        "macro.chl.captchaErr": 1341,
//                        "macro.chl.jschlErr": 5323
//                      }
//                    },
//                    "pageviews": {
//                      "all": 5724723,
//                      "search_engine": {
//                        "googlebot": 35272,
//                        "pingdom": 13435,
//                        "bingbot": 5372,
//                        "baidubot": 1345
//                      }
//                    },
//                    "uniques": {
//                      "all": 12343
//                    }
//                  }
//                ]
//              },
//              "query": {
//                "since": "2015-01-01T12:23:00Z",
//                "until": "2015-01-02T12:23:00Z",
//                "time_delta": 60
//              }
//            }
//        """.data(using: .utf8)!
//
//        let json: [String: Any]
//        do {
//            json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
//        } catch {
//            return nil
//        }
        
        self.makeRequest(endpoint: "zones/"+zoneId+"/analytics/dashboard", method: .get, showActInd: false, completion: { response in
            if let results = response["result"] as? [String: Any],
                let totals = results["totals"] as? [String: Any],
                let requests = totals["requests"] as? [String: Any],
                let requests_cached = requests["cached"] as? Int,
                let requests_uncached = requests["uncached"] as? Int,
                let top_countries = requests["country"] as? [String: Int],
                let threats = totals["threats"] as? [String: Any],
                let threats_all = threats["all"] as? Int,
                let pageviews = totals["pageviews"] as? [String: Any],
                let pageviews_all = pageviews["all"] as? Int {
                for a in top_countries{
                    print("------")
                    print(a.key)
                    print(a.value)
                }
                completion([
                    "requests_cached": requests_cached,
                    "requests_uncached": requests_uncached,
                    "top_countries": top_countries,
                    "threats": threats_all,
                    "pageviews": pageviews_all
                    ])
            } else {
                    completion(nil)
            }
        })
        
    }
    
    // Creat the analytics
    
    /**
     Calls Clourflare's billing API endpoint and retrieves their subscription costs
     
     API documentation:
     [GET user/subscriptions](https://api.cloudflare.com/#user-subscription-properties)
     
     - Returns: The cost per month of the user's subscription
     */
    public func getCosts(completion: @escaping (_ data: [String: Any]?)->()) {
//        let data: Data = """
//            {
//              "success": true,
//              "errors": [],
//              "messages": [],
//              "result": [
//                {
//                  "app": {
//                    "install_id": null
//                  },
//                  "id": "506e3185e9c882d175a2d0cb0093d9f2",
//                  "state": "Paid",
//                  "price": 20,
//                  "currency": "USD",
//                  "component_values": [
//                    {
//                      "name": "page_rules",
//                      "value": 20,
//                      "default": 5,
//                      "price": 5
//                    }
//                  ],
//                  "zone": {
//                    "id": "023e105f4ecef8ad9ca31a8372d0c353",
//                    "name": "example.com"
//                  },
//                  "frequency": "monthly",
//                  "rate_plan": {
//                    "id": "free",
//                    "public_name": "Business Plan",
//                    "currency": "USD",
//                    "scope": "zone",
//                    "sets": [
//                      {}
//                    ],
//                    "is_contract": false,
//                    "externally_managed": false
//                  },
//                  "current_period_end": "2014-03-31T12:20:00Z",
//                  "current_period_start": "2014-05-11T12:20:00Z"
//                }
//              ]
//            }
//        """.data(using: .utf8)!
//
//        let json: [String: Any]
//        do {
//            json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
//        } catch {
//            return nil
//        }
        
        
        self.makeRequest(endpoint: "user/subscriptions", method: .get, showActInd: false, completion: { response in
            if let resultsArray = response["result"] as? [Any] {
                if resultsArray.count > 0 {
                    if let results = resultsArray[0] as? [String: Any],
                        let price = results["price"] as? Float {
                        completion([
                            "price": price
                            ])
                    } else {
                        completion(nil)
                    }
                }
            }
        })
    }
    
    /**
     Calls Clourflare's GraphQL API to retrieve a list of incoming requests
     
     API documentation:
     [GraphQL](https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-firewall-events)
     - Parameters:
     - zoneId: The id of the zone that you want the list of requests for
     - Returns: The cost per month of the user's subscription
     */
    public func getRequests(zoneId: String, completion: @escaping (_ data:[[String: Any]]?)->()) {
//        let data: Data = """
//            {
//              "data": {
//                "viewer": {
//                  "zones": [
//                    {
//                      "firewallEventsAdaptive": [
//                        {
//                          "action": "get",
//                          "clientAsn": "5089",
//                          "clientCountryName": "AU",
//                          "clientIP": "220.253.122.100",
//                          "clientRequestPath": "/%3Cscript%3Ealert()%3C/script%3E",
//                          "clientRequestQuery": "",
//                          "datetime": "2020-08-26T06:34:20+0000",
//                          "source": "waf",
//                          "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
//                        },
//                        {
//                          "action": "log",
//                          "clientAsn": "5089",
//                          "clientCountryName": "GB",
//                          "clientIP": "203.0.113.69",
//                          "clientRequestPath": "/%3Cscript%3Ealert()%3C/script%3E",
//                          "clientRequestQuery": "",
//                          "datetime": "2020-04-24T10:11:03Z",
//                          "source": "waf",
//                          "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
//                        },
//                        {
//                          "action": "post",
//                          "clientAsn": "5089",
//                          "clientCountryName": "US",
//                          "clientIP": "203.0.113.233",
//                          "clientRequestPath": "/%3Cscript%3Ealert()%3C/script%3E",
//                          "clientRequestQuery": "",
//                          "datetime": "2020-04-24T09:12:49Z",
//                          "source": "waf",
//                          "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
//                        },
//                        {
//                          "action": "get",
//                          "clientAsn": "5089",
//                          "clientCountryName": "US",
//                          "clientIP": "203.0.113.233",
//                          "clientRequestPath": "/%3Cscript%3Ealert()%3C/script%3E",
//                          "clientRequestQuery": "",
//                          "datetime": "2020-04-24T09:11:24Z",
//                          "source": "waf",
//                          "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
//                        },
//                        {
//                          "action": "allow",
//                          "clientASNDescription": "ASN-TELSTRA Telstra Corporation Ltd",
//                          "clientAsn": "1221",
//                          "clientCountryName": "AU",
//                          "clientIP": "2001:8003:d4c0:5f00:62a4:4cff:fe5c:b8e0",
//                          "clientRequestHTTPHost": "jwrc.me",
//                          "clientRequestHTTPMethodName": "GET",
//                          "clientRequestHTTPProtocol": "HTTP/2",
//                          "clientRequestPath": "/updatepackages",
//                          "clientRequestQuery": "?token=26760d07c7b06da3ac7d27946b4853e0665c50e0a8b705269b2cfd48f061de2b",
//                          "datetime": "2020-08-28T06:00:01Z",
//                          "rayName": "5c9bcf425b05fe80",
//                          "ruleId": "47520303b099459194235bdf4ebcd3a2",
//                          "source": "firewallrules",
//                          "userAgent": "curl/7.58.0",
//                          "matchIndex": 0,
//                          "metadata": [
//                            {
//                              "key": "filter",
//                              "value": "9ad6a60213524589bb74aed55d908dd0"
//                            },
//                            {
//                              "key": "type",
//                              "value": "customer"
//                            }
//                          ],
//                          "sampleInterval": 1
//                        }
//                      ]
//                    }
//                  ]
//                }
//              },
//              "errors": null
//            }
//        """.data(using: .utf8)!
//
//        let json: [String: Any]
//        do {
//            json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
//        } catch {
//            return nil
//        }
        let date = Calendar.current.date(byAdding: .second, value: 400, to: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        let graphQLData = [
                "query": "query ListFirewallEvents($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) {viewer {zones(filter: { zoneTag: $zoneTag }) {firewallEventsAdaptive(filter: $filter limit: 10 orderBy: [datetime_DESC]) {action clientAsn clientCountryName clientIP clientRequestPath clientRequestQuery datetime source userAgent}}}}",
                "variables": [
                    "zoneTag": zoneId,
                    "filter": [
                        "datetime_geq": formatter.string(from: date!)
                    ]
                ]
            ] as Parameters
        print(graphQLData)
        self.makeRequest(endpoint: "graphql", method: .post, data: graphQLData, showActInd: false, completion: { response in
//            print(response)
            if let dataArray = response["data"] as? [String: Any],
                let viewer = dataArray["viewer"] as? [String: Any],
                let zones = viewer["zones"] as? [Any],
                let zone = zones[0] as? [String: Any],
                let requests = zone["firewallEventsAdaptive"] as? [[String: Any]] {
                completion(requests)
            } else {
                completion(nil)
            }
        })
        
//        guard let dataArray = json["data"] as? [String: Any],
//            let viewer = dataArray["viewer"] as? [String: Any],
//            let zones = viewer["zones"] as? [Any],
//            let zone = zones[0] as? [String: Any],
//            let requests = zone["firewallEventsAdaptive"] as? [[String: Any]]
//
//            else {
//                return nil
//        }
//
//        return requests
    }
    
    public func getDNS(zoneId: String) -> [[String: Any]]? {
        let data: Data = """
                {
                "success": true,
                "errors": [],
                "messages": [],
                "result": [
                {
                    "id": "372e67954025e0ba6aaa6d586b9e0b59",
                    "type": "A",
                    "name": "example.com",
                    "content": "198.51.100.4",
                    "proxiable": true,
                    "proxied": false,
                    "ttl": 120,
                    "locked": false,
                    "zone_id": "023e105f4ecef8ad9ca31a8372d0c353",
                    "zone_name": "example.com",
                    "created_on": "2014-01-01T05:20:00.12345Z",
                    "modified_on": "2014-01-01T05:20:00.12345Z",
                    "data": {},
                    "meta": {
                        "auto_added": true,
                        "source": "primary"
                    }
                },
                {
                    "id": "372e67954025e0ba6aaa6d586b9e0b59",
                    "type": "CNAME",
                    "name": "google.com",
                    "content": "216.58.200.110",
                    "proxiable": true,
                    "proxied": false,
                    "ttl": 120,
                    "locked": false,
                    "zone_id": "023e105f4ecef8ad9ca31a8372d0c353",
                    "zone_name": "example.com",
                    "created_on": "2014-01-01T05:20:00.12345Z",
                    "modified_on": "2014-01-01T05:20:00.12345Z",
                    "data": {},
                    "meta": {
                        "auto_added": true,
                        "source": "primary"
                    }
                },
                {
                    "id": "372e67954025e0ba6aaa6d586b9e0b59",
                    "type": "CNAME",
                    "name": "instagram.com",
                    "content": "52.22.200.157",
                    "proxiable": true,
                    "proxied": false,
                    "ttl": 120,
                    "locked": false,
                    "zone_id": "023e105f4ecef8ad9ca31a8372d0c353",
                    "zone_name": "example.com",
                    "created_on": "2014-01-01T05:20:00.12345Z",
                    "modified_on": "2014-01-01T05:20:00.12345Z",
                    "data": {},
                    "meta": {
                        "auto_added": true,
                        "source": "primary"
                    }
                },
                {
                    "id": "372e67954025e0ba6aaa6d586b9e0b59",
                    "type": "CNAME",
                    "name": "rmit.edu.au",
                    "content": "131.170.0.105",
                    "proxiable": true,
                    "proxied": false,
                    "ttl": 120,
                    "locked": false,
                    "zone_id": "023e105f4ecef8ad9ca31a8372d0c353",
                    "zone_name": "example.com",
                    "created_on": "2014-01-01T05:20:00.12345Z",
                    "modified_on": "2014-01-01T05:20:00.12345Z",
                    "data": {},
                    "meta": {
                        "auto_added": true,
                        "source": "primary"
                    }
                },
            ]
        }
        """.data(using: .utf8)!
        
        let json: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            return nil
        }
        
        guard let results = json["result"] as? [[String: Any]]
            else {
                return nil
        }
        
        return results
    }
    
    /**
     Updates an existing DNS listing by making a request to Cloudflares API
     
     - Returns: Returns true if successful and false if not
     */
    public func updateDNS() -> Bool {
        // var hardcoded to true for testing
        let success: Bool = true
        
        // pass data to API
        // if pass is successful
        // set success to true and return
        // else set success to false and return
        return success
    }
    
    /**
     Sends new DNS data to Cloudflare API
     
     - Returns: Returns true if successful and false if not
     */
    public func newDNS () -> Bool {
        // var hardcoded to true for testing
        let success: Bool = true
        
        // pass data to API
        // if pass is successful
        // set success to true and return
        // else set success to false and return
        return success
    }
}
