import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let jar = UTType(filenameExtension: "jar") ?? .archive
}
