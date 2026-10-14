import Foundation

public struct VisualKey: Identifiable, Hashable {
    public var id: String { "\(keyCode)-\(label)" }
    public var keyCode: UInt16
    public var label: String
    public var subLabel: String?
    public var width: Double // in key units (1.0 = normal key)
    public var height: Double // in key units
    
    public init(keyCode: UInt16, label: String, subLabel: String? = nil, width: Double = 1.0, height: Double = 1.0) {
        self.keyCode = keyCode
        self.label = label
        self.subLabel = subLabel
        self.width = width
        self.height = height
    }
}

public struct KeyboardVisualizerLayout {
    public static func defaultOrnataV3XLayout() -> [[VisualKey]] {
        return [
            // Row 0: Function Row
            [
                VisualKey(keyCode: 53, label: "Esc"),
                VisualKey(keyCode: 122, label: "F1"),
                VisualKey(keyCode: 120, label: "F2"),
                VisualKey(keyCode: 99, label: "F3"),
                VisualKey(keyCode: 118, label: "F4"),
                VisualKey(keyCode: 96, label: "F5"),
                VisualKey(keyCode: 97, label: "F6"),
                VisualKey(keyCode: 98, label: "F7"),
                VisualKey(keyCode: 100, label: "F8"),
                VisualKey(keyCode: 101, label: "F9", subLabel: "M"),
                VisualKey(keyCode: 109, label: "F10", subLabel: "G"),
                VisualKey(keyCode: 103, label: "F11"),
                VisualKey(keyCode: 111, label: "F12"),
                VisualKey(keyCode: 105, label: "PrtSc"),
                VisualKey(keyCode: 107, label: "ScrLk"),
                VisualKey(keyCode: 113, label: "Pause")
            ],
            // Row 1: Number Row
            [
                VisualKey(keyCode: 50, label: "`", subLabel: "~"),
                VisualKey(keyCode: 18, label: "1", subLabel: "!"),
                VisualKey(keyCode: 19, label: "2", subLabel: "@"),
                VisualKey(keyCode: 20, label: "3", subLabel: "#"),
                VisualKey(keyCode: 21, label: "4", subLabel: "$"),
                VisualKey(keyCode: 23, label: "5", subLabel: "%"),
                VisualKey(keyCode: 22, label: "6", subLabel: "^"),
                VisualKey(keyCode: 26, label: "7", subLabel: "&"),
                VisualKey(keyCode: 28, label: "8", subLabel: "*"),
                VisualKey(keyCode: 25, label: "9", subLabel: "("),
                VisualKey(keyCode: 29, label: "0", subLabel: ")"),
                VisualKey(keyCode: 27, label: "-", subLabel: "_"),
                VisualKey(keyCode: 24, label: "=", subLabel: "+"),
                VisualKey(keyCode: 51, label: "Backspace", width: 2.0),
                VisualKey(keyCode: 114, label: "Ins"),
                VisualKey(keyCode: 115, label: "Home"),
                VisualKey(keyCode: 116, label: "PgUp")
            ],
            // Row 2: QWERTY Row
            [
                VisualKey(keyCode: 48, label: "Tab", width: 1.5),
                VisualKey(keyCode: 12, label: "Q"),
                VisualKey(keyCode: 13, label: "W"),
                VisualKey(keyCode: 14, label: "E"),
                VisualKey(keyCode: 15, label: "R"),
                VisualKey(keyCode: 17, label: "T"),
                VisualKey(keyCode: 16, label: "Y"),
                VisualKey(keyCode: 32, label: "U"),
                VisualKey(keyCode: 34, label: "I"),
                VisualKey(keyCode: 31, label: "O"),
                VisualKey(keyCode: 35, label: "P"),
                VisualKey(keyCode: 33, label: "[", subLabel: "{"),
                VisualKey(keyCode: 30, label: "]", subLabel: "}"),
                VisualKey(keyCode: 42, label: "\\", subLabel: "|", width: 1.5),
                VisualKey(keyCode: 117, label: "Del"),
                VisualKey(keyCode: 119, label: "End"),
                VisualKey(keyCode: 121, label: "PgDn")
            ],
            // Row 3: ASDF Row
            [
                VisualKey(keyCode: 57, label: "Caps Lock", width: 1.75),
                VisualKey(keyCode: 0, label: "A"),
                VisualKey(keyCode: 1, label: "S"),
                VisualKey(keyCode: 2, label: "D"),
                VisualKey(keyCode: 3, label: "F"),
                VisualKey(keyCode: 5, label: "G"),
                VisualKey(keyCode: 4, label: "H"),
                VisualKey(keyCode: 38, label: "J"),
                VisualKey(keyCode: 40, label: "K"),
                VisualKey(keyCode: 37, label: "L"),
                VisualKey(keyCode: 41, label: ";", subLabel: ":"),
                VisualKey(keyCode: 39, label: "'", subLabel: "\""),
                VisualKey(keyCode: 36, label: "Enter", width: 2.25)
            ],
            // Row 4: ZXCV Row
            [
                VisualKey(keyCode: 56, label: "Shift", width: 2.25),
                VisualKey(keyCode: 6, label: "Z"),
                VisualKey(keyCode: 7, label: "X"),
                VisualKey(keyCode: 8, label: "C"),
                VisualKey(keyCode: 9, label: "V"),
                VisualKey(keyCode: 11, label: "B"),
                VisualKey(keyCode: 45, label: "N"),
                VisualKey(keyCode: 46, label: "M"),
                VisualKey(keyCode: 43, label: ",", subLabel: "<"),
                VisualKey(keyCode: 47, label: ".", subLabel: ">"),
                VisualKey(keyCode: 44, label: "/", subLabel: "?"),
                VisualKey(keyCode: 60, label: "Shift", width: 2.75),
                VisualKey(keyCode: 126, label: "▲")
            ],
            // Row 5: Bottom Row
            [
                VisualKey(keyCode: 59, label: "Ctrl", width: 1.25),
                VisualKey(keyCode: 58, label: "Opt", width: 1.25),
                VisualKey(keyCode: 55, label: "Cmd", width: 1.25),
                VisualKey(keyCode: 49, label: "Space", width: 6.25),
                VisualKey(keyCode: 55, label: "Cmd", width: 1.25),
                VisualKey(keyCode: 58, label: "Opt", width: 1.25),
                VisualKey(keyCode: 110, label: "Fn", width: 1.25),
                VisualKey(keyCode: 59, label: "Ctrl", width: 1.25),
                VisualKey(keyCode: 123, label: "◀"),
                VisualKey(keyCode: 125, label: "▼"),
                VisualKey(keyCode: 124, label: "▶")
            ]
        ]
    }
    
    public static func defaultNumpadLayout() -> [[VisualKey]] {
        return [
            [
                VisualKey(keyCode: 71, label: "Num"),
                VisualKey(keyCode: 75, label: "/"),
                VisualKey(keyCode: 67, label: "*"),
                VisualKey(keyCode: 78, label: "-")
            ],
            [
                VisualKey(keyCode: 89, label: "7"),
                VisualKey(keyCode: 91, label: "8"),
                VisualKey(keyCode: 92, label: "9"),
                VisualKey(keyCode: 69, label: "+", height: 2.0)
            ],
            [
                VisualKey(keyCode: 86, label: "4"),
                VisualKey(keyCode: 87, label: "5"),
                VisualKey(keyCode: 88, label: "6")
            ],
            [
                VisualKey(keyCode: 83, label: "1"),
                VisualKey(keyCode: 84, label: "2"),
                VisualKey(keyCode: 85, label: "3"),
                VisualKey(keyCode: 76, label: "Enter", height: 2.0)
            ],
            [
                VisualKey(keyCode: 82, label: "0", width: 2.0),
                VisualKey(keyCode: 65, label: ".")
            ]
        ]
    }
}
