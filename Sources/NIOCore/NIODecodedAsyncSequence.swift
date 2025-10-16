//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence where Element == ByteBuffer {
    /// Decode the `AsyncSequence<ByteBuffer>` into a sequence of `Element`s,
    /// using the `Decoder`, where `Decoder.InboundOut` matches `Element`.
    ///
    /// Usage:
    /// ```swift
    /// let myDecoder = MyNIOSingleStepByteToMessageDecoder()
    /// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
    /// let decodedSequence = baseSequence.decode(using: myDecoder)
    ///
    /// for try await element in decodedSequence {
    ///     print("Decoded an element!", element)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - decoder: The `Decoder` to use to decode the ``ByteBuffer``s.
    ///   - maximumBufferSize: The maximum number of bytes to aggregate in-memory.
    ///     An error will be thrown if after decoding an element there is more aggregated data than this amount.
    /// - Returns: A ``NIODecodedAsyncSequence`` that decodes the ``ByteBuffer``s into a sequence of `Element`s.
    @inlinable
    public func decode<Decoder: NIOSingleStepByteToMessageDecoder>(
        using decoder: Decoder,
        maximumBufferSize: Int? = nil
    ) -> NIODecodedAsyncSequence<Self, Decoder> {
        NIODecodedAsyncSequence(
            asyncSequence: self,
            decoder: decoder,
            maximumBufferSize: maximumBufferSize
        )
    }

    /// Returns the longest possible subsequences of the sequence, in order, that
    /// don't contain elements satisfying the given predicate. Elements that are
    /// used to split the sequence are not returned as part of any subsequence.
    ///
    /// Similar to standard library's `String.split(maxSplits:omittingEmptySubsequences:whereSeparator:)`.
    ///
    /// Usage:
    /// ```swift
    /// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
    /// let splitSequence = baseSequence.split(whereSeparator: { $0 == UInt8(ascii: " ") })
    ///
    /// for try await buffer in splitSequence {
    ///     print("Split by whitespaces!\n", buffer.hexDump(format: .detailed))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each pair of consecutive elements
    ///     satisfying the `isSeparator` predicate and for each element at the
    ///     start or end of the sequence satisfying the `isSeparator` predicate.
    ///     If `true`, only nonempty subsequences are returned. The default
    ///     value is `true`.
    ///   - isSeparator: A closure that returns `true` if its argument should be
    ///     used to split the file's bytes; otherwise, `false`.
    /// - Returns: An `AsyncSequence` of ``ByteBuffer``s, split from the this async sequence's bytes.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the file.
    @inlinable
    public func split(
        omittingEmptySubsequences: Bool = true,
        maximumBufferSize: Int? = nil,
        whereSeparator isSeparator: @escaping (UInt8) -> Bool
    ) -> NIODecodedAsyncSequence<Self, NIOSplitMessageDecoder> {
        self.decode(
            using: NIOSplitMessageDecoder(
                omittingEmptySubsequences: omittingEmptySubsequences,
                whereSeparator: isSeparator
            ),
            maximumBufferSize: maximumBufferSize
        )
    }

    /// Returns the longest possible subsequences of the sequence, in order,
    /// around elements equal to the given element.
    ///
    /// Similar to standard library's `String.split(separator:maxSplits:omittingEmptySubsequences:)`.
    ///
    /// Usage:
    /// ```swift
    /// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
    /// let splitSequence = baseSequence.split(separator: UInt8(ascii: " "))
    ///
    /// for try await buffer in splitSequence {
    ///     print("Split by separator!\n", buffer.hexDump(format: .detailed))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - separator: The element that should be split upon.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each consecutive pair of `separator`
    ///     elements in the sequence and for each instance of `separator` at the
    ///     start or end of the sequence. If `true`, only nonempty subsequences
    ///     are returned. The default value is `true`.
    /// - Returns: An `AsyncSequence` of ``ByteBuffer``s, split from the this async sequence's bytes.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the file.
    @inlinable
    public func split(
        separator: UInt8,
        omittingEmptySubsequences: Bool = true,
        maximumBufferSize: Int? = nil
    ) -> NIODecodedAsyncSequence<Self, NIOSplitMessageDecoder> {
        self.split(
            omittingEmptySubsequences: omittingEmptySubsequences,
            maximumBufferSize: maximumBufferSize,
            whereSeparator: { $0 == separator }
        )
    }

    /// Returns the longest possible subsequences of the sequence, in order,
    /// that are separated by a line break.
    ///
    /// The following Characters are considered line breaks, similar to
    /// standard library's `String.split(whereSeparator: \.isNewline)`:
    /// - "\n" (U+000A): LINE FEED (LF)
    /// - U+000B: LINE TABULATION (VT)
    /// - U+000C: FORM FEED (FF)
    /// - "\r" (U+000D): CARRIAGE RETURN (CR)
    /// - "\r\n" (U+000D U+000A): CR-LF
    ///
    /// The following Characters are NOT considered line breaks, unlike in
    /// standard library's `String.split(whereSeparator: \.isNewline)`:
    /// - U+0085: NEXT LINE (NEL)
    /// - U+2028: LINE SEPARATOR
    /// - U+2029: PARAGRAPH SEPARATOR
    ///
    /// This is because these characters would require unicode and data-encoding awareness, which
    /// are outside swift-nio's scope.
    ///
    /// Usage:
    /// ```swift
    /// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
    /// let splitLinesSequence = baseSequence.splitLines()
    ///
    /// for try await buffer in splitLinesSequence {
    ///     print("Split by line breaks!\n", buffer.hexDump(format: .detailed))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each consecutive line break in the sequence.
    ///     If `true`, only nonempty subsequences are returned. The default value is `true`.
    /// - Returns: An `AsyncSequence` of ``ByteBuffer``s, split from the this async sequence's bytes.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the file.
    @inlinable
    public func splitLines(
        omittingEmptySubsequences: Bool = true,
        maximumBufferSize: Int? = nil
    ) -> NIODecodedAsyncSequence<Self, NIOSplitLinesMessageDecoder> {
        self.decode(
            using: NIOSplitLinesMessageDecoder(omittingEmptySubsequences: omittingEmptySubsequences),
            maximumBufferSize: maximumBufferSize
        )
    }
}

// MARK: - NIODecodedAsyncSequence

/// A type that decodes an `AsyncSequence<ByteBuffer>` into a sequence of ``Element``s,
/// using the `Decoder`, where `Decoder.InboundOut` matches ``Element``.
///
/// Use `AsyncSequence/decode(using:maximumBufferSize:)` to create a ``NIODecodedAsyncSequence``.
///
/// Usage:
/// ```swift
/// let myDecoder = MyNIOSingleStepByteToMessageDecoder()
/// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
/// let decodedSequence = baseSequence.decode(using: myDecoder)
///
/// for try await element in decodedSequence {
///     print("Decoded an element!", element)
/// }
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct NIODecodedAsyncSequence<
    Base: AsyncSequence,
    Decoder: NIOSingleStepByteToMessageDecoder
> where Base.Element == ByteBuffer {
    @usableFromInline
    var asyncSequence: Base
    @usableFromInline
    var decoder: Decoder
    @usableFromInline
    var maximumBufferSize: Int?

    @inlinable
    init(asyncSequence: Base, decoder: Decoder, maximumBufferSize: Int? = nil) {
        self.asyncSequence = asyncSequence
        self.decoder = decoder
        self.maximumBufferSize = maximumBufferSize
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension NIODecodedAsyncSequence: AsyncSequence {
    public typealias Element = Decoder.InboundOut

    /// Create an ``AsyncIterator`` for this ``NIODecodedAsyncSequence``.
    @inlinable
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: self)
    }

    /// An ``AsyncIterator`` over a ``NIODecodedAsyncSequence``.
    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        enum State: Sendable {
            case canReadFromBaseIterator
            case baseIteratorIsExhausted
            case finishedDecoding
        }

        @usableFromInline
        var baseIterator: Base.AsyncIterator
        @usableFromInline
        var processor: NIOSingleStepByteToMessageProcessor<Decoder>
        @usableFromInline
        var state: State

        @inlinable
        init(base: NIODecodedAsyncSequence) {
            self.baseIterator = base.asyncSequence.makeAsyncIterator()
            self.processor = NIOSingleStepByteToMessageProcessor(
                base.decoder,
                maximumBufferSize: base.maximumBufferSize
            )
            self.state = .canReadFromBaseIterator
        }

        /// Retrieve the next element from the ``NIODecodedAsyncSequence``.
        ///
        /// The same as `next(isolation:)` but not isolated to an actor, which allows
        /// for less availability restrictions.
        @inlinable
        public mutating func next() async throws -> Element? {
            while true {
                switch self.state {
                case .finishedDecoding:
                    return nil
                case .canReadFromBaseIterator:
                    let (decoded, ended) = try self.processor.decodeNext(
                        decodeMode: .normal,
                        seenEOF: false
                    )

                    // We expect `decodeNext()` to only return `ended == true` only if we've notified it
                    // that we've read the last chunk from the buffer, using `decodeMode: .last`.
                    assert(!ended)

                    if let decoded {
                        return decoded
                    }

                    // Read more data into the buffer so we can decode more messages
                    guard let nextBuffer = try await self.baseIterator.next() else {
                        // Ran out of data to read.
                        self.state = .baseIteratorIsExhausted
                        continue
                    }
                    self.processor.append(nextBuffer)
                case .baseIteratorIsExhausted:
                    let (decoded, ended) = try self.processor.decodeNext(
                        decodeMode: .last,
                        seenEOF: true
                    )

                    if ended {
                        self.state = .finishedDecoding
                    }

                    return decoded
                }
            }

            fatalError("Unreachable code")
        }

        /// Retrieve the next element from the ``NIODecodedAsyncSequence``.
        ///
        /// The same as `next()` but isolated to an actor.
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        @inlinable
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Element? {
            while true {
                switch self.state {
                case .finishedDecoding:
                    return nil
                case .canReadFromBaseIterator:
                    let (decoded, ended) = try self.processor.decodeNext(
                        decodeMode: .normal,
                        seenEOF: false
                    )

                    // We expect `decodeNext()` to only return `ended == true` only if we've notified it
                    // that we've read the last chunk from the buffer, using `decodeMode: .last`.
                    assert(!ended)

                    if let decoded {
                        return decoded
                    }

                    // Read more data into the buffer so we can decode more messages
                    guard let nextBuffer = try await self.baseIterator.next(isolation: actor) else {
                        // Ran out of data to read.
                        self.state = .baseIteratorIsExhausted
                        continue
                    }
                    self.processor.append(nextBuffer)
                case .baseIteratorIsExhausted:
                    let (decoded, ended) = try self.processor.decodeNext(
                        decodeMode: .last,
                        seenEOF: true
                    )

                    if ended {
                        self.state = .finishedDecoding
                    }

                    return decoded
                }
            }

            fatalError("Unreachable code")
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension NIODecodedAsyncSequence: Sendable where Base: Sendable, Decoder: Sendable {}

@available(*, unavailable)
extension NIODecodedAsyncSequence.AsyncIterator: Sendable {}

// MARK: - NIOSplitMessageDecoder

/// A decoder which splits the data into subsequences that are separated by a given separator.
/// Similar to standard library's `String.split(separator:maxSplits:omittingEmptySubsequences:)`.
///
/// Use `AsyncSequence/split(omittingEmptySubsequences:maximumBufferSize:whereSeparator:)`
/// or `AsyncSequence/split(separator:omittingEmptySubsequences:maximumBufferSize:)` to create a
/// `NIODecodedAsyncSequence` that uses this decoder.
///
/// Usage:
/// ```swift
/// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
/// let splitSequence = baseSequence.split(separator: UInt8(ascii: " "))
///
/// for try await buffer in splitSequence {
///     print("Split by separator!\n", buffer.hexDump(format: .detailed))
/// }
/// ```
public struct NIOSplitMessageDecoder: NIOSingleStepByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer

    @usableFromInline
    let omittingEmptySubsequences: Bool
    @usableFromInline
    let isSeparator: (UInt8) -> Bool
    @usableFromInline
    var ended: Bool

    @inlinable
    init(
        omittingEmptySubsequences: Bool,
        whereSeparator isSeparator: @escaping (UInt8) -> Bool
    ) {
        self.omittingEmptySubsequences = omittingEmptySubsequences
        self.isSeparator = isSeparator
        self.ended = false
    }

    /// Decode the next message from the given buffer.
    @inlinable
    mutating func decode(
        buffer: inout ByteBuffer,
        hasReceivedLastChunk: Bool
    ) throws -> (buffer: InboundOut, separator: UInt8?)? {
        if self.ended { return nil }

        while true {
            guard let separatorIndex = buffer.readableBytesView.firstIndex(where: self.isSeparator) else {
                guard hasReceivedLastChunk else {
                    // Need more data
                    return nil
                }

                self.ended = true

                if self.omittingEmptySubsequences,
                    buffer.readableBytes == 0
                {
                    return nil
                }

                // Just send the whole buffer if we're at the last chunk but we can find no separators
                // Safe to force unwrap. `buffer.readableBytes` is `0` in the worst case.
                let slice = buffer.readSlice(length: buffer.readableBytes)!

                return (slice, nil)
            }

            // Safe to force unwrap. We just found a separator somewhere in the buffer.
            let slice = buffer.readSlice(length: separatorIndex - buffer.readerIndex)!

            if self.omittingEmptySubsequences,
                slice.readableBytes == 0
            {
                // Mark the separator itself as read
                buffer._moveReaderIndex(forwardBy: 1)
                continue
            }

            // Read the separator itself
            // Safe to force unwrap. We just found a separator somewhere in the buffer.
            let separator = buffer.readInteger(as: UInt8.self)!

            return (slice, separator)
        }
    }

    /// Decode the next message separated by the provided separator.
    /// To be used when we're still receiving data.
    @inlinable
    public mutating func decode(buffer: inout ByteBuffer) throws -> InboundOut? {
        try self.decode(buffer: &buffer, hasReceivedLastChunk: false)?.buffer
    }

    /// Decode the next message separated by the provided separator.
    /// To be used when the last chunk of data has been received.
    @inlinable
    public mutating func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> InboundOut? {
        try self.decode(buffer: &buffer, hasReceivedLastChunk: true)?.buffer
    }
}

@available(*, unavailable)
extension NIOSplitMessageDecoder: Sendable {}

// MARK: - NIOSplitLinesMessageDecoder

/// A decoder which splits the data into subsequences that are separated by a line break.
///
/// Use `AsyncSequence/splitLines(omittingEmptySubsequences:maximumBufferSize:)` to create a
/// `NIODecodedAsyncSequence` that uses this decoder.
///
/// The following Characters are considered line breaks, similar to
/// standard library's `String.split(whereSeparator: \.isNewline)`:
/// - "\n" (U+000A): LINE FEED (LF)
/// - U+000B: LINE TABULATION (VT)
/// - U+000C: FORM FEED (FF)
/// - "\r" (U+000D): CARRIAGE RETURN (CR)
/// - "\r\n" (U+000D U+000A): CR-LF
///
/// The following Characters are NOT considered line breaks, unlike in
/// standard library's `String.split(whereSeparator: \.isNewline)`:
/// - U+0085: NEXT LINE (NEL)
/// - U+2028: LINE SEPARATOR
/// - U+2029: PARAGRAPH SEPARATOR
///
/// This is because these characters would require unicode and data-encoding awareness, which
/// are outside swift-nio's scope.
///
/// Usage:
/// ```swift
/// let baseSequence = MyAsyncSequence<ByteBuffer>(...)
/// let splitLinesSequence = baseSequence.splitLines()
///
/// for try await buffer in splitLinesSequence {
///     print("Split by line breaks!\n", buffer.hexDump(format: .detailed))
/// }
/// ```
public struct NIOSplitLinesMessageDecoder: NIOSingleStepByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer

    @usableFromInline
    var splitDecoder: NIOSplitMessageDecoder
    @usableFromInline
    var previousSeparatorWasCR: Bool

    @inlinable
    init(omittingEmptySubsequences: Bool) {
        self.splitDecoder = NIOSplitMessageDecoder(
            omittingEmptySubsequences: omittingEmptySubsequences,
            whereSeparator: Self.isLineBreak
        )
        self.previousSeparatorWasCR = false
    }

    /// - "\n" (U+000A): LINE FEED (LF)
    /// - U+000B: LINE TABULATION (VT)
    /// - U+000C: FORM FEED (FF)
    /// - "\r" (U+000D): CARRIAGE RETURN (CR)
    /// - "\r\n" (U+000D U+000A): CR-LF
    ///
    /// "\r\n" is manually accounted for during the decoding.
    @inlinable
    static func isLineBreak(_ byte: UInt8) -> Bool {
        // First check <= \r. Most bytes won't pass this check, so we can return earlier than if we checked >= \n first.
        byte <= UInt8(ascii: "\r") && byte >= UInt8(ascii: "\n")
    }

    /// Decode the next message from the given buffer.
    @inlinable
    mutating func decode(buffer: inout ByteBuffer, hasReceivedLastChunk: Bool) throws -> InboundOut? {
        while true {
            guard
                let (slice, separator) = try self.splitDecoder.decode(
                    buffer: &buffer,
                    hasReceivedLastChunk: hasReceivedLastChunk
                )
            else {
                return nil
            }

            // If we are getting rid of empty subsequences then it doesn't matter if we detect
            // \r\n as CR+LF, or as a CR + a LF. The backing decoder gets rid of the empty subsequence
            // anyway. Therefore, we can return early right here and skip the rest of the logic.
            if self.splitDecoder.omittingEmptySubsequences {
                return slice
            }

            // "\r\n" is 2 bytes long, so we need to manually account for it.
            switch separator {
            case UInt8(ascii: "\n") where slice.readableBytes == 0:
                let isCRLF = self.previousSeparatorWasCR
                self.previousSeparatorWasCR = false
                if isCRLF {
                    continue
                }
            case UInt8(ascii: "\r"):
                self.previousSeparatorWasCR = true
            default:
                self.previousSeparatorWasCR = false
            }

            return slice
        }
    }

    /// Decode the next message separated by one of the ASCII line breaks.
    /// To be used when we're still receiving data.
    @inlinable
    public mutating func decode(buffer: inout ByteBuffer) throws -> InboundOut? {
        try self.decode(buffer: &buffer, hasReceivedLastChunk: false)
    }

    /// Decode the next message separated by one of the ASCII line breaks.
    /// To be used when the last chunk of data has been received.
    @inlinable
    public mutating func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> InboundOut? {
        try self.decode(buffer: &buffer, hasReceivedLastChunk: true)
    }
}

@available(*, unavailable)
extension NIOSplitLinesMessageDecoder: Sendable {}
