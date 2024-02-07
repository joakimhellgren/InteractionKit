<h1> InteractionKit</h1>

<p>
    <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" />
    <img src="https://img.shields.io/badge/macOS-14.0+-orange.svg" />
    <img src="https://img.shields.io/badge/-SwiftUI-red.svg" />
</p>

InteractionKit is a collection of UI components initially intended for live performances on iOS and macOS.

## Installation

1. Select File -> Add Packages...
2. Click the `+` icon on the bottom left of the Collections sidebar on the left.
3. Choose `Add Swift Package Collection` from the pop-up menu.
4. In the `Add Package Collection` dialog box, enter `https://github.com/joakimhellgren/InteractionKit.git` as the URL and click the "Load" button.

## Examples

### VerticalDrawer - inspired by Logic Pro's keyboard sheet. 

```swift
GeometryReader {
    Color.mint.grayscale(0.85)
    VerticalDrawer(
        in: $0,
        topContent: { Text("Placeholder #1") },
        mainContent: { Text("Placeholder #1") },
        bottomContent: { Text("Placeholder #3") }
    )
}
```

### TouchView - Multi-touch in SwiftUI context.

```swift
TouchView {
    Color.mint.grayscale(0.85)
}
```

### MomentaryButton - A momentary logic gate commonly found in modular synthesizer systems

```swift
@State var isOn = false
MomentaryButton(isOn: $isOn) {
    Circle().fill(isOn ? .green : .orange)
}
``` 
