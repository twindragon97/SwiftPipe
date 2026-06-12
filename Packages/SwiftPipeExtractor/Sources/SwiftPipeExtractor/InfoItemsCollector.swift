// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/InfoItemsCollector.java @ v0.26.3
//
// Deviations: the Collector interface is folded into this base class (a
// protocol with associated types cannot be subclassed the way the Java
// hierarchy needs). Comparator<I> maps to an areInIncreasingOrder closure.
// commit() adds unexpected error types to the error list (Java's checked
// exceptions make that case impossible).

open class InfoItemsCollector<I: InfoItem, E> {
    private var itemList: [I] = []
    private var errors: [Error] = []
    private let serviceId: Int
    private let comparator: ((I, I) -> Bool)?

    /// Create a new collector with no comparator / sorting function.
    public convenience init(_ serviceId: Int) {
        self.init(serviceId, nil)
    }

    /// Create a new collector.
    public init(_ serviceId: Int, _ comparator: ((I, I) -> Bool)?) {
        self.serviceId = serviceId
        self.comparator = comparator
    }

    public func getItems() -> [I] {
        if let comparator {
            itemList.sort(by: comparator)
        }
        return itemList
    }

    public func getErrors() -> [Error] {
        errors
    }

    public func reset() {
        itemList.removeAll()
        errors.removeAll()
    }

    /// Add an error.
    public func addError(_ error: Error) {
        errors.append(error)
    }

    /// Add an item.
    public func addItem(_ item: I) {
        itemList.append(item)
    }

    /// Get the service id.
    public func getServiceId() -> Int {
        serviceId
    }

    /// Try to extract the item from an extractor without adding it to the
    /// collection (Java: Collector.extract, abstract here).
    open func extract(_ extractor: E) throws -> I {
        preconditionFailure("InfoItemsCollector.extract must be overridden")
    }

    /// Try to add an extractor to the collection.
    public func commit(_ extractor: E) {
        do {
            addItem(try extract(extractor))
        } catch is FoundAdException {
            // found an ad. Maybe a debug line could be placed here
        } catch let e as ParsingException {
            addError(e)
        } catch {
            addError(error)
        }
    }
}
