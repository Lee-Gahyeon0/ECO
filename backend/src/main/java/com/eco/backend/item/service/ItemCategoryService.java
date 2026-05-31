package com.eco.backend.item.service;

import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.rule.ItemCategoryRule;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class ItemCategoryService {

    private final List<ItemCategoryRule> rules = List.of(
            new ItemCategoryRule("음료", List.of(
                    "생수", "삼다수", "아이시스", "탄산수", "콜라", "사이다", "주스", "커피", "물"
            )),
            new ItemCategoryRule("식품", List.of(
                    "라면", "과자", "빵", "김밥", "도시락", "우유", "계란", "햄", "치즈"
            )),
            new ItemCategoryRule("생활용품", List.of(
                    "물티슈", "휴지", "세제", "샴푸", "린스", "비누", "칫솔", "치약"
            )),
            new ItemCategoryRule("일회용품", List.of(
                    "종이컵", "플라스틱컵", "빨대", "비닐봉지", "일회용", "나무젓가락"
            )),
            new ItemCategoryRule("전자제품", List.of(
                    "건전지", "충전기", "케이블", "이어폰", "마우스", "키보드"
            )),
            new ItemCategoryRule("의류", List.of(
                    "티셔츠", "바지", "양말", "속옷", "모자", "신발"
            ))
    );

    public ItemCategoryResponse classify(String itemName) {
        validateItemName(itemName);

        String normalizedName = normalize(itemName);

        MatchResult bestMatch = null;

        for (ItemCategoryRule rule : rules) {
            for (String keyword : rule.getKeywords()) {
                if (normalizedName.contains(keyword)) {
                    if (bestMatch == null || keyword.length() > bestMatch.keyword().length()) {
                        bestMatch = new MatchResult(rule.getCategory(), keyword);
                    }
                }
            }
        }

        if (bestMatch != null) {
            return new ItemCategoryResponse(
                    itemName,
                    normalizedName,
                    bestMatch.category(),
                    bestMatch.keyword()
            );
        }

        return new ItemCategoryResponse(
                itemName,
                normalizedName,
                "기타",
                null
        );
    }

    public List<ItemCategoryResponse> classifyAll(List<String> itemNames) {
        if (itemNames == null || itemNames.isEmpty()) {
            throw new IllegalArgumentException("품목 목록은 비어 있을 수 없습니다.");
        }

        return itemNames.stream()
                .map(this::classify)
                .toList();
    }

    private void validateItemName(String itemName) {
        if (itemName == null || itemName.trim().isEmpty()) {
            throw new IllegalArgumentException("품목명은 비어 있을 수 없습니다.");
        }
    }

    private String normalize(String itemName) {
        return itemName
                .trim()
                .replaceAll("\\s+", "")
                .replaceAll("[0-9]+", "")
                .replaceAll("ml|ML|l|L|g|G|kg|KG|개|입|팩|병|봉|매", "")
                .toLowerCase();
    }

    private record MatchResult(String category, String keyword) {
    }
}