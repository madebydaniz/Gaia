import Foundation
import Testing
@testable import Gaia

struct BingWallpaperRepositoryTests {
    @Test func mapsBingDTOToWallpaper() throws {
        let json = """
        {
          "startdate": "20260430",
          "fullstartdate": "202604300700",
          "enddate": "20260501",
          "url": "/th?id=OHR.Test_1920x1080.jpg&rf=LaDigue_1920x1080.jpg",
          "urlbase": "/th?id=OHR.Test",
          "copyright": "Test copyright",
          "copyrightlink": "https://www.bing.com/search?q=test",
          "title": "Test title",
          "hsh": "abc123"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(BingWallpaperDTO.self, from: json)
        let wallpaper = dto.toDomain()

        #expect(wallpaper.id == "bing_abc123")
        #expect(wallpaper.source == .bing)
        #expect(wallpaper.title == "Test title")
        #expect(wallpaper.imageURL?.host == "www.bing.com")
        #expect(wallpaper.thumbnailURL?.absoluteString.contains("_400x240.jpg") == true)
        #expect(wallpaper.sourcePageURL?.absoluteString == "https://www.bing.com/search?q=test")
    }
}
