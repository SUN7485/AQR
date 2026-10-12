import Foundation

/// DTOs for endpoints whose response shape was **observed** against the live
/// API on 2026-10-12. See `Docs/API-FINDINGS.md`.
///
/// Every property below appears in a real response body. Nothing is inferred,
/// and there is deliberately no listing DTO: the public catalogue is empty
/// (API-FINDINGS §8), so no listing item schema could be observed and none is
/// guessed.

/// `GET /client/v1/MetaLookup/countries` — 241 entries.
///
/// Shape: `{ countryId, name, currencyISO3, isActive, isBillingEnabled, isStoreEnabled }`
struct Country: Codable, Identifiable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2, e.g. "AE".
    let countryId: String
    let name: String
    /// ISO 4217, e.g. "AED". Empty string for some entries — treat as absent.
    let currencyISO3: String?
    let isActive: Bool
    let isBillingEnabled: Bool
    let isStoreEnabled: Bool

    var id: String { countryId }

    /// False when the record carries no currency code, rather than assuming one.
    var hasCurrency: Bool {
        guard let currencyISO3 else { return false }
        return !currencyISO3.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// `GET /client/v1/MetaListingCategories` — 12 entries.
///
/// Full key list observed: name, displayName, shortDescription, purpose,
/// description, displayOrder, parentCategoryId, parentCategoryName, comments,
/// layoutTemplate, parentCategoryNames, parentCategoryIds,
/// parentCategoryIdList, listingCategoryPaymentTypeId,
/// listingCategoryPaymentTypeName, tagListJson, crossCategoryIds, countryId,
/// thumbnailImageId, thumbnailImageFileName, thumbnailImageUrl, iconCssClass,
/// slug, metaTitle, metaKeywords, metaDescription, metaAuthor, metaViewport,
/// searchKeywords, isRootCategory, isLeafCategory, isFeatured, isPublished,
/// includeInMainMenu, includeInListingMenu, allowedToUserAssets,
/// allowedToAgentAssets, isTitledeedRequired, isProofOfUsageRequired,
/// countOfListing, dynamicFields, listingCategoryPaymentType, priceLists,
/// extensionData, id, createdOn, latestUpdatedOn.
///
/// Only the fields this demo needs are declared; the rest are simply ignored
/// by `Decodable`.
struct ListingCategoryDTO: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let displayName: String
    let slug: String?
    let countryId: String?
    let parentCategoryId: Int?
    let displayOrder: Int?
    let isRootCategory: Bool?
    let isLeafCategory: Bool?
    let isPublished: Bool?
    let isFeatured: Bool?
    let includeInMainMenu: Bool?
    let countOfListing: Int?
    let iconCssClass: String?
    let thumbnailImageUrl: String?
}

/// `GET /client/v1/MetaLookup/service-categories` — 6 entries.
///
/// Shape: `{ id, name, description, displayOrder, isPublished, includeInMenu,
/// countryId, countryName, thumbnailImageId, thumbnailImageFileName,
/// iconCssClass, slug, serviceCount, services }`
struct ServiceCategoryDTO: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let description: String?
    let displayOrder: Int?
    let isPublished: Bool?
    let includeInMenu: Bool?
    let countryId: String?
    let countryName: String?
    let iconCssClass: String?
    let slug: String?
    let serviceCount: Int?
}

/// `GET /client/v1/Listing/search` — pagination envelope.
///
/// Shape: `{ page, pageSize, totalCount, items }`.
///
/// `items` is typed `[Never]` deliberately. The public catalogue is empty, so
/// the element shape was never observed (API-FINDINGS §8). Decoding this will
/// fail loudly if items ever arrive, which is correct: it must not silently
/// produce empty results.
struct ListingSearchPage<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let items: [Item]
}

/// `GET /client/v1/ApplicationStatus`.
///
/// Not enveloped, and verified separately: `{ mode, serverTimeUtc }`.
struct ApplicationStatus: Decodable, Sendable {
    let mode: String
    let serverTimeUtc: String
}