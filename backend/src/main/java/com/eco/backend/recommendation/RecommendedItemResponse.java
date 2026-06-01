package com.example.back.recommendation;

public record RecommendedItemResponse(
        String originalItem,
        String normalizedItem,
        String recommendedItem,
        String reason
) {
}