package com.example.back.recommendation;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @PostMapping("/items")
    public List<RecommendedItemResponse> recommendItems(
            @RequestBody RecommendationRequest request
    ) {
        return recommendationService.recommendItems(request);
    }

    @PostMapping("/places")
    public List<RecommendedPlaceResponse> recommendPlaces(
            @RequestBody RecommendationRequest request
    ) {
        return recommendationService.recommendPlaces(request);
    }
}