package com.example.back.recommendation;

import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class RecommendationService {

    public List<RecommendedItemResponse> recommendItems(RecommendationRequest request) {
        List<RecommendedItemResponse> responses = new ArrayList<>();

        if (request.items() == null || request.items().isEmpty()) {
            return responses;
        }

        for (String rawItem : request.items()) {
            String normalizedItem = normalizeItem(rawItem);

            switch (normalizedItem) {
                case "생수" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "텀블러",
                        "플라스틱병 사용을 줄일 수 있습니다."
                ));

                case "샴푸" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "샴푸바",
                        "플라스틱 용기 사용을 줄일 수 있습니다."
                ));

                case "세탁세제" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "세제 리필",
                        "새 플라스틱 용기 구매를 줄일 수 있습니다."
                ));

                case "물티슈" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "손수건",
                        "일회용 폐기물 사용을 줄일 수 있습니다."
                ));

                case "일회용컵" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "텀블러",
                        "일회용 컵 사용을 줄일 수 있습니다."
                ));

                case "비닐봉투" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "장바구니",
                        "일회용 비닐봉투 사용을 줄일 수 있습니다."
                ));

                case "건전지" -> responses.add(new RecommendedItemResponse(
                        rawItem,
                        normalizedItem,
                        "충전지",
                        "반복 구매와 폐기물 발생을 줄일 수 있습니다."
                ));

                default -> {
                    // 아직 추천 규칙이 없는 품목은 제외
                }
            }
        }

        return responses;
    }

    public List<RecommendedPlaceResponse> recommendPlaces(RecommendationRequest request) {
        List<RecommendedPlaceResponse> responses = new ArrayList<>();

        if (request.items() == null || request.items().isEmpty()) {
            return responses;
        }

        boolean needZeroWasteShop = false;
        boolean needRefillStation = false;
        boolean needBatteryBox = false;

        for (String rawItem : request.items()) {
            String normalizedItem = normalizeItem(rawItem);

            switch (normalizedItem) {
                case "생수", "샴푸", "물티슈", "일회용컵", "비닐봉투" -> needZeroWasteShop = true;
                case "세탁세제" -> needRefillStation = true;
                case "건전지" -> needBatteryBox = true;
                default -> {
                }
            }
        }

        if (needZeroWasteShop) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 제로웨이스트샵",
                    "제로웨이스트샵",
                    "부산광역시 부산진구",
                    35.157,
                    129.059,
                    "친환경 생활용품과 대체 아이템을 구매할 수 있습니다."
            ));
        }

        if (needRefillStation) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 리필스테이션",
                    "리필스테이션",
                    "부산광역시 부산진구",
                    35.158,
                    129.061,
                    "세탁세제 리필이 가능한 장소입니다."
            ));
        }

        if (needBatteryBox) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 폐건전지 수거함",
                    "폐건전지수거함",
                    "부산광역시 부산진구",
                    35.156,
                    129.058,
                    "건전지는 일반쓰레기가 아닌 전용 수거함에 배출하는 것이 좋습니다."
            ));
        }

        return responses;
    }

    private String normalizeItem(String rawItemName) {
        if (rawItemName == null) {
            return "";
        }

        String item = rawItemName
                .replaceAll("\\s+", "")
                .toLowerCase();

        if (item.contains("삼다수") ||
                item.contains("아이시스") ||
                item.contains("백산수") ||
                item.contains("생수")) {
            return "생수";
        }

        if (item.contains("샴푸") ||
                item.contains("엘라스틴") ||
                item.contains("려")) {
            return "샴푸";
        }

        if (item.contains("세탁세제") ||
                item.contains("퍼실") ||
                item.contains("비트")) {
            return "세탁세제";
        }

        if (item.contains("물티슈")) {
            return "물티슈";
        }

        if (item.contains("일회용컵") ||
                item.contains("종이컵") ||
                item.contains("플라스틱컵")) {
            return "일회용컵";
        }

        if (item.contains("비닐봉투") ||
                item.contains("봉투")) {
            return "비닐봉투";
        }

        if (item.contains("건전지") ||
                item.contains("배터리")) {
            return "건전지";
        }

        return rawItemName;
    }
}