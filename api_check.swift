import MapKit
import CoreLocation

func test() async {
    let request = MKGeocodingRequest(addressString: "test")
    // This should fail and hopefully give us the correct method names
    // let _ = try? await request?.start() 
}
