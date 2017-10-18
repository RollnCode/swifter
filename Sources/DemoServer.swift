//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation


public func demoServer(_ publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = shareFilesFromDirectory(publicDir)

    server["/files/:path"] = directoryBrowser("/")

    server["/"] = scopes {
        html {
            body {
                ul(server.routes) { service in
                    li {
                        a { href = service; inner = service }
                    }
                }
            }
        }
    }
    
    server["/magic"] = { (r, h) in h(.ok(.html("You asked for " + r.path))) }
    
    server["/test/:param1/:param2"] = { (r, h) in
        scopes {
            html {
                body {
                    h3 { inner = "Address: \(r.address ?? "unknown")" }
                    h3 { inner = "Url: \(r.path)" }
                    h3 { inner = "Method: \(r.method)" }
                    
                    h3 { inner = "Query:" }
                    
                    table(r.queryParams) { param in
                        tr {
                            td { inner = param.0 }
                            td { inner = param.1 }
                        }
                    }
                    
                    h3 { inner = "Headers:" }
                    
                    table(r.headers) { header in
                        tr {
                            td { inner = header.0 }
                            td { inner = header.1 }
                        }
                    }
                    
                    h3 { inner = "Route params:" }
                    
                    table(r.params) { param in
                        tr {
                            td { inner = param.0 }
                            td { inner = param.1 }
                        }
                    }
                }
            }
        }(r, h)
    }
    
    server.GET["/upload"] = scopes {
        html {
            body {
                form {
                    method = "POST"
                    action = "/upload"
                    enctype = "multipart/form-data"
                    
                    input { name = "my_file1"; type = "file" }
                    input { name = "my_file2"; type = "file" }
                    input { name = "my_file3"; type = "file" }
                    
                    button {
                        type = "submit"
                        inner = "Upload"
                    }
                }
            }
        }
    }
    
    server.POST["/upload"] = { (r, h) in
        var response = ""
        for multipart in r.parseMultiPartFormData() {
            guard let name = multipart.name, let fileName = multipart.fileName else { continue }
            response += "Name: \(name) File name: \(fileName) Size: \(multipart.body.count)<br>"
        }
        h(.ok(.html(response)))
    }
    
    server.GET["/login"] = scopes {
        html {
            head {
                script { src = "http://cdn.staticfile.org/jquery/2.1.4/jquery.min.js" }
                stylesheet { href = "http://cdn.staticfile.org/twitter-bootstrap/3.3.0/css/bootstrap.min.css" }
            }
            body {
                h3 { inner = "Sign In" }
                
                form {
                    method = "POST"
                    action = "/login"
                    
                    fieldset {
                        input { placeholder = "E-mail"; name = "email"; type = "email"; autofocus = "" }
                        input { placeholder = "Password"; name = "password"; type = "password"; autofocus = "" }
                        a {
                            href = "/login"
                            button {
                                type = "submit"
                                inner = "Login"
                            }
                        }
                    }
                    
                }
                javascript {
                    src = "http://cdn.staticfile.org/twitter-bootstrap/3.3.0/js/bootstrap.min.js"
                }
            }
        }
    }
    
    server.POST["/login"] = { (r, h) in
        let formFields = r.parseUrlencodedForm()
        h(.ok(.html(formFields.map({ "\($0.0) = \($0.1)" }).joined(separator: "<br>"))))
    }
    
    server["/demo"] = scopes {
        html {
            body {
                center {
                    h2 { inner = "Hello Swift" }
                    img { src = "https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png" }
                }
            }
        }
    }
    
    server["/raw"] = { (r, h) in
        h( HttpResponse.raw(200, "OK", ["XXX-Custom-Header": "value"], { try $0.write([UInt8]("test".utf8)) }) )
    }
    
    server["/redirect"] = { (r, h) in
        h( .movedPermanently("http://www.google.com") )
    }

    server["/long"] = { (r, h) in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        h( .ok(.html(longResponse)) )
    }
    
    server["/wildcard/*/test/*/:param"] = { (r, h) in
        h(.ok(.html(r.path)))
    }
    
    server["/stream"] = { (r, h) in
        h( HttpResponse.raw(200, "OK", nil, { w in
            for i in 0...100 {
                try w.write([UInt8]("[chunk \(i)]".utf8))
            }
        }))
    }
    
    server["/websocket-echo"] = websocket({ (session, text) in
        session.writeText(text)
        }, { (session, binary) in
        session.writeBinary(binary)
    })
    
    server.notFoundHandler = { (r, h) in
        h( .movedPermanently("https://github.com/404") )
    }
    
//    server.middleware.append { r in
//        print("Middleware: \(r.address ?? "unknown address") -> \(r.method) -> \(r.path)")
//        return nil
//    }
    
    return server
}
    
