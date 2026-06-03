package com.eco.backend.recommendation.dto;

import java.util.List;

public record RecommendationRequest(
        List<String> items,
        Double lat,
        Double lng
) {
}