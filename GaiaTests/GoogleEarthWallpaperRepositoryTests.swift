import Foundation
import Testing
@testable import Gaia

struct GoogleEarthWallpaperRepositoryTests {
    @Test func mapsGoogleEarthDTOToWallpaper() throws {
        let json = """
        {
          "id": "earth-1",
          "title": "Earth",
          "description": "A view",
          "locationName": "Somewhere",
          "imageURL": "https://example.com/full.jpg",
          "thumbnailURL": "https://example.com/thumb.jpg",
          "sourcePageURL": "https://example.com/source",
          "width": 1800,
          "height": 1200,
          "copyright": "Google Earth"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(GoogleEarthWallpaperDTO.self, from: json)
        let wallpaper = dto.toDomain()

        #expect(wallpaper.id == "googleEarth_earth-1")
        #expect(wallpaper.source == .googleEarth)
        #expect(wallpaper.locationName == "Somewhere")
        #expect(wallpaper.width == 1800)
    }
}
