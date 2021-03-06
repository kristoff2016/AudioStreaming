//
//  Created by Dimitrios Chatzieleftheriou on 28/05/2020.
//  Copyright © 2020 Decimal. All rights reserved.
//

import AudioToolbox.AudioFile
import Foundation

struct HeaderField {
    public static let acceptRanges = "Accept-Ranges"
    public static let contentLength = "Content-Length"
    public static let contentType = "Content-Type"
    public static let contentRange = "Content-Range"
}

enum IcyHeaderField {
    public static let icyMentaint = "icy-metaint"
}

struct HTTPHeaderParserOutput {
    let supportsSeek: Bool
    let fileLength: Int
    let typeId: AudioFileTypeID
    // Metadata Support
    let metadataStep: Int
}

struct HTTPHeaderParser: Parser {
    typealias Input = HTTPURLResponse
    typealias Output = HTTPHeaderParserOutput?

    func parse(input: HTTPURLResponse) -> HTTPHeaderParserOutput? {
        guard let headers = input.allHeaderFields as? [String: String], !headers.isEmpty else { return nil }

        let supportsSeek = headers[HeaderField.acceptRanges] != "none"

        var typeId: UInt32 = 0
        if let contentType = input.mimeType {
            typeId = audioFileType(mimeType: contentType)
        }

        var fileLength: Int = 0
        if input.statusCode == 200 {
            if let contentLength = headers[HeaderField.contentLength],
               let length = Int(contentLength)
            {
                fileLength = length
            }
        } else if input.statusCode == 206 {
            if let contentLength = headers[HeaderField.contentRange] {
                let components = contentLength.components(separatedBy: "/")
                if components.count == 2 {
                    if let last = components.last, let length = Int(last) {
                        fileLength = length
                    }
                }
            }
        }

        var metadataStep = 0
        if let icyMetaint = headers[IcyHeaderField.icyMentaint],
           let intValue = Int(icyMetaint)
        {
            metadataStep = intValue
        }

        return HTTPHeaderParserOutput(supportsSeek: supportsSeek,
                                      fileLength: fileLength,
                                      typeId: typeId,
                                      metadataStep: metadataStep)
    }
}
