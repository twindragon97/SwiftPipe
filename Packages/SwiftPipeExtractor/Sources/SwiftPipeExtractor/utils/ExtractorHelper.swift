// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/ExtractorHelper.java @ v0.26.3
//
// Partial port: only getItemsPageOrLogError is ported here. The other two
// methods (getRelatedItemsOrLogError / getRelatedVideosOrLogError) depend on
// StreamInfo and land with it in the YouTube batch.

public enum ExtractorHelper {
    public static func getItemsPageOrLogError<T: InfoItem>(
        _ info: Info, _ extractor: ListExtractor<T>
    ) -> InfoItemsPage<T> {
        do {
            let page = try extractor.getInitialPage()
            info.addAllErrors(page.getErrors())
            return page
        } catch {
            info.addError(error)
            return InfoItemsPage.emptyPage()
        }
    }
}
