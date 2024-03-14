//
//  ControllersProps.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 13/03/24.
//

struct HashableControllersProps: Hashable {
    var color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    init(dictionary: NSDictionary) {
        self.color = transformStringIntoUIColor(color: dictionary["color"] as? String)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(color)
    }

    static func == (lhs: HashableControllersProps, rhs: HashableControllersProps) -> Bool {
        return lhs.color == rhs.color
    }
}

struct HashableControllers: Hashable {
    var playbackControl: HashableControllersProps

  init(playbackControl: HashableControllersProps) {
      print("p: \(playbackControl.color)")
        self.playbackControl = playbackControl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(playbackControl)
    }

    static func == (lhs: HashableControllers, rhs: HashableControllers) -> Bool {
        return lhs.playbackControl == rhs.playbackControl
    }
}
