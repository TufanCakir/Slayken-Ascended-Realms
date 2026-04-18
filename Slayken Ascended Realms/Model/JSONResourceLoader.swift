//
//  JSONResourceLoader.swift
//  Slayken Ascended Realms
//

import Foundation

enum JSONResourceLoader {
    static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json"
            )
        else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    static func loadArray<T: Decodable>(_ type: T.Type, resource: String) -> [T]
    {
        load([T].self, resource: resource) ?? []
    }
}
