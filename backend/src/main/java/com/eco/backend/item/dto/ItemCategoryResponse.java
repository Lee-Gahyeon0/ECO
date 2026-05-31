package com.eco.backend.item.dto;

public class ItemCategoryResponse {

    private String originalName;
    private String normalizedName;
    private String category;
    private String matchedKeyword;

    public ItemCategoryResponse() {
    }

    public ItemCategoryResponse(
            String originalName,
            String normalizedName,
            String category,
            String matchedKeyword
    ) {
        this.originalName = originalName;
        this.normalizedName = normalizedName;
        this.category = category;
        this.matchedKeyword = matchedKeyword;
    }

    public String getOriginalName() {
        return originalName;
    }

    public String getNormalizedName() {
        return normalizedName;
    }

    public String getCategory() {
        return category;
    }

    public String getMatchedKeyword() {
        return matchedKeyword;
    }
}