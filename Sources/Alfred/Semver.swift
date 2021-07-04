//
//  Semver.swift
//
//  This file is part of Semver. - https://github.com/ddddxxx/Semver
//  Copyright (c) 2017 Xander Deng
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//

import Foundation

/// Represents a version conforming to [Semantic Versioning 2.0.0](http://semver.org).
public struct Semver {

  /// The major version.
  public let major: Int

  /// The minor version.
  public let minor: Int

  /// The patch version.
  public let patch: Int

  /// Creates a version with the provided values.
  ///
  /// The result is unchecked. Use `isValid` to validate the version.
  public init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  /// A Boolean value indicating whether the version conforms to Semantic
  /// Versioning 2.0.0.
  ///
  /// An invalid Semver can only be formed with the memberwise initializer
  /// `Semver.init(major:minor:patch:)`.
  public var isValid: Bool {
    return major >= 0
      && minor >= 0
      && patch >= 0
  }
}

extension Semver: Equatable {

  /// Semver semantic equality.
  public static func ==(lhs: Semver, rhs: Semver) -> Bool {
    return lhs.major == rhs.major &&
      lhs.minor == rhs.minor &&
      lhs.patch == rhs.patch
  }

  /// Swift semantic equality.
  public static func ===(lhs: Semver, rhs: Semver) -> Bool {
    return (lhs == rhs)
  }

  /// Swift semantic unequality.
  public static func !==(lhs: Semver, rhs: Semver) -> Bool {
    return !(lhs === rhs)
  }
}

extension Semver: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(major)
    hasher.combine(minor)
    hasher.combine(patch)
  }
}

extension Semver: Comparable {

  public static func <(lhs: Semver, rhs: Semver) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
    return false
  }
}

extension Semver: Codable {

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    guard let version = Semver(str) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid semantic version")
    }
    self = version
  }
}

extension Semver: LosslessStringConvertible {

  public init?(_ description:String) {
    var versions = description.split(
      separator: ".",
      omittingEmptySubsequences: false
    )
    if versions.count > 3 || versions.count < 1 { return nil }
    if versions.count == 1 { versions += ["0", "0"] }
    if versions.count == 2 { versions += ["0"] }

    guard let major = Int(versions[0]),
          let minor = Int(versions[1]),
          let patch = Int(versions[2]) else {
      return nil
    }

    self.major = major
    self.minor = minor
    self.patch = patch
  }

  public var description: String {
    return "\(major).\(minor).\(patch)"
  }
}

extension Semver: ExpressibleByStringLiteral {

  public init(stringLiteral value: StaticString) {
    guard let v = Semver(value.description) else {
      preconditionFailure("failed to initialize `Semver` using string literal '\(value)'.")
    }
    self = v
  }
}

// MARK: Foundation Extensions

extension Bundle {

  /// Use `CFBundleShortVersionString` key
  public var semanticVersion: Semver? {
    return (infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(Semver.init(_:))
  }
}

extension ProcessInfo {

  public var operatingSystemSemanticVersion: Semver {
    let v = operatingSystemVersion
    return Semver(major: v.majorVersion, minor: v.minorVersion, patch: v.patchVersion)
  }
}

// MARK: - Utilities

private extension CharacterSet {

  static let semverIdentifierAllowed: CharacterSet = {
    var set = CharacterSet(charactersIn: "0"..."9")
    set.insert(charactersIn: "a"..."z")
    set.insert(charactersIn: "A"..."Z")
    set.insert("-")
    return set
  }()

  static let asciiDigits = CharacterSet(charactersIn: "0"..."9")
}

private extension String {

  subscript(nsRange: NSRange) -> String? {
    guard let r = Range(nsRange, in: self) else {
      return nil
    }
    return String(self[r])
  }
}
