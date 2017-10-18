//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func shareFile(_ path: String) -> HttpRouterHandler {
    return { (r, h) in
        if let file = try? path.openForReading() {
            h(.raw(200, "OK", [:], { writer in
                try? writer.write(file)
                file.close()
            }))
        } else {
            h(.notFound)
        }
    }
}

public func shareFilesFromDirectory(_ directoryPath: String, defaults: [String] = ["index.html", "default.html"]) -> HttpRouterHandler {
    return { (r, h) in
        guard let fileRelativePath = r.params.first else {
            h(.notFound)
            return
        }
        if fileRelativePath.value.isEmpty {
            for path in defaults {
                if let file = try? (directoryPath + String.pathSeparator + path).openForReading() {
                    h(.raw(200, "OK", [:], { writer in
                        try? writer.write(file)
                        file.close()
                    }))
                    return
                }
            }
        }
        if let file = try? (directoryPath + String.pathSeparator + fileRelativePath.value).openForReading() {
            h(.raw(200, "OK", [:], { writer in
                try? writer.write(file)
                file.close()
            }))
            return
        }
        h(.notFound)
    }
}

public func directoryBrowser(_ dir: String) -> HttpRouterHandler {
    return { (r, h) in
        guard let (_, value) = r.params.first else {
            h(.notFound)
            return
        }
        let filePath = dir + String.pathSeparator + value
        do {
            guard try filePath.exists() else {
                h(.notFound)
                return
            }
            if try filePath.directory() {
                let files = try filePath.files()
                scopes {
                    html {
                        body {
                            table(files) { file in
                                tr {
                                    td {
                                        a {
                                            href = r.path + "/" + file
                                            inner = file
                                        }
                                    }
                                }
                            }
                        }
                    }
                    }(r, h)
                return
            } else {
                guard let file = try? filePath.openForReading() else {
                    h(.notFound)
                    return
                }
                h(.raw(200, "OK", [:], { writer in
                    try? writer.write(file)
                    file.close()
                }))
                return
            }
        } catch {
            h(.internalServerError)
        }
    }
}
