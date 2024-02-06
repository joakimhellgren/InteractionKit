# InteractionKit

## VerticalDrawer usage:

```swift
GeometryReader { proxy in
    Color.mint.grayscale(0.85)
    VerticalDrawer(
        in: proxy,
        contentFraction: 0...1,
        barFraction: 0.09,
        barStyle: .bar,
        contentStyle: .regularMaterial,
        strokeStyle: .tertiary,
        topContent: { Text("Placeholder #1") },
        mainContent: { Text("Placeholder #2") },
        bottomContent: { Text("Placeholder #3") }
    )
}    
```
