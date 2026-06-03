# Universal Mobile UI Design Rules

> 이 문서는 특정 서비스 기획, 기능명, 화면명, 도메인에 종속되지 않는 범용 모바일 UI 디자인 규칙입니다.  
> 다양한 앱/웹 서비스의 디자인 기준으로 재사용할 수 있도록 색상, 타이포그래피, 레이아웃, 컴포넌트, 인터랙션 중심으로 정리합니다.

---

## 1. Design Direction

전체 UI는 부드럽고 안정적인 프리미엄 모바일 서비스 느낌을 지향합니다.

- 밝고 따뜻한 배경 위에 흰색 카드 중심의 구조를 사용합니다.
- 정보는 카드 단위로 큼직하게 나누어 배치합니다.
- 복잡한 선, 강한 그림자, 과도한 장식은 사용하지 않습니다.
- 전체적으로 눈이 편한 파스텔 톤을 사용합니다.
- 화면은 친근하고 신뢰감 있으며 계속 사용하고 싶게 느껴져야 합니다.
- 둥근 모서리, 넉넉한 여백, 명확한 위계를 통해 편안한 사용 경험을 제공합니다.
- 특정 브랜드, 특정 서비스, 특정 기능을 연상시키는 고유 명칭이나 시각 요소는 사용하지 않습니다.

---

## 2. Color Rules

### Base Colors

| Role | Color |
|---|---|
| App Background | `#F2F5FA` or `#F4F7FB` |
| White Surface | `#FFFFFF` |
| Primary Text | `#344154` |
| Secondary Text | `#738096` |
| Light Border | `#DDE5EF` |
| Divider | `#E8EDF3` |

### Accent Colors

| Role | Color |
|---|---|
| Main Accent | `#58BE82` |
| Active Accent | `#4FB879` |
| Soft Mint Surface | `#E6F4F0` |
| Soft Blue Surface | `#EAF2FA` |
| Warning / Alert | `#F05A4A` |
| Point Yellow | `#FFE177` |
| Purple Accent | `#C982F2` |

### Color Usage Guidelines

- 전체 채도는 낮게 유지합니다.
- 배경색은 매우 연한 회색, 민트, 블루 계열을 우선 사용합니다.
- 주요 CTA, 선택 상태, 활성 상태에는 Main Accent 계열을 사용합니다.
- 경고, 실패, 긴급 상태에는 Warning / Alert 색상을 제한적으로 사용합니다.
- 강조 색상은 화면 전체의 10~20% 이내로만 사용합니다.
- 텍스트는 대부분 Primary Text를 사용하고, 보조 정보에는 Secondary Text를 사용합니다.
- 검정색 `#000000`은 직접 사용하지 않고, 부드러운 다크 네이비 계열 텍스트를 사용합니다.

---

## 3. Typography Rules

### Font Direction

- 한글 UI는 Pretendard 또는 Noto Sans KR 계열의 부드럽고 현대적인 산세리프 폰트 느낌을 사용합니다.
- 글자는 얇기보다 적당히 두껍고 안정적인 인상을 주어야 합니다.
- 제목, 주요 숫자, 버튼 텍스트는 굵게 처리합니다.

### Type Scale

| Usage | Size | Weight |
|---|---:|---:|
| Main Title | 26~32px | `w800` |
| Section Title | 22~26px | `w800` |
| Card Title | 20~24px | `w700` |
| Body Text | 15~17px | `w500` |
| Caption / Label | 12~14px | `w500~w600` |
| Numeric Data | 30~42px | `w800` |
| Button Text | 18~22px | `w800` |

### Text Guidelines

- 제목은 짧고 명확하게 작성합니다.
- 본문은 1~2줄 안에서 읽히도록 간결하게 구성합니다.
- 한 화면 안에서 너무 많은 폰트 크기를 섞지 않습니다.
- 숫자, 상태, 핵심 정보는 크기와 굵기로 명확히 구분합니다.
- 보조 텍스트는 Primary Text보다 낮은 명도와 작은 크기를 사용합니다.

---

## 4. Shape Rules

전체 UI는 둥글고 부드러운 형태를 기본으로 합니다.

| Element | Radius |
|---|---:|
| Large Section Container | 32~40px |
| General Card | 24~32px |
| Button | 22~30px |
| Chip / Tag | 999px pill |
| Icon Box | 18~24px |
| Image Thumbnail | 18~24px |
| Floating Button | Circle or 999px pill |

### Shape Guidelines

- 각진 사각형 UI는 사용하지 않습니다.
- 카드와 버튼은 충분히 둥근 모서리를 적용합니다.
- 작은 요소도 최소 16px 이상의 radius를 적용해 부드럽게 만듭니다.
- 중요한 CTA는 pill 형태 또는 큰 radius의 사각형 버튼으로 구성합니다.

---

## 5. Shadow & Border Rules

### Border

- 카드에는 아주 연한 border를 사용합니다.
- 기본 border color는 `#DDE5EF`를 사용합니다.
- 구분선은 `#E8EDF3`를 사용하며 1px 느낌으로 얇게 처리합니다.

### Shadow

- 무거운 그림자는 사용하지 않습니다.
- 필요한 경우에만 매우 약한 shadow를 사용합니다.
- 권장값:
  - Blur: 8~14
  - Opacity: 0.04~0.08
  - Y offset: 2~6

### Guidelines

- 카드 구분은 shadow보다 background, border, spacing으로 해결합니다.
- 그림자는 떠 있는 버튼, 강조 카드, 모달 등에만 제한적으로 사용합니다.
- 어두운 그림자나 강한 elevation은 피합니다.

---

## 6. Layout Rules

### Screen Layout

- 모바일 우선 UI를 기준으로 설계합니다.
- 390~430px 폭의 모바일 화면에서 가장 자연스럽게 보이도록 구성합니다.
- Safe Area를 고려하여 상단과 하단 영역이 잘리지 않도록 합니다.
- 전체 화면은 필요한 경우 자연스럽게 스크롤 가능해야 합니다.

### Spacing

| Usage | Value |
|---|---:|
| Horizontal Screen Padding | 20~24px |
| Section Spacing | 28~40px |
| Card Internal Padding | 20~28px |
| Element Gap | 12~20px |
| Button Height | 56~68px |
| Bottom Navigation Height | 78~88px |

### Layout Guidelines

- 화면 좌우 여백은 넉넉하게 유지합니다.
- 섹션 사이에는 충분한 간격을 두어 정보가 답답해 보이지 않게 합니다.
- 하나의 화면에 너무 많은 정보를 압축하지 않습니다.
- 핵심 정보는 상단 또는 시선이 먼저 가는 카드에 배치합니다.
- 카드 내부에는 텍스트, 아이콘, 버튼이 숨 쉴 수 있는 충분한 여백을 둡니다.
- 그리드, 리스트, 카드형 레이아웃을 상황에 맞게 사용하되 구조는 단순하게 유지합니다.

---

## 7. Card Design Rules

카드는 주요 정보를 묶는 기본 단위로 사용합니다.

### Default Card

- Background: `#FFFFFF`
- Radius: 24~32px
- Padding: 20~28px
- Border: `#DDE5EF`
- Shadow: 없음 또는 매우 약하게

### Soft Container Card

- Background: `#E6F4F0`, `#EAF2FA`, 또는 연한 gradient
- Radius: 32~40px
- 내부에 흰색 카드나 작은 정보 블록을 배치할 수 있습니다.
- 섹션을 시각적으로 분리할 때 사용합니다.

### Data Card

- 핵심 숫자나 상태 정보를 강조할 때 사용합니다.
- 숫자는 30~42px, `w800`으로 표시합니다.
- 보조 라벨은 12~16px, Secondary Text로 표시합니다.
- 아이콘 박스를 함께 배치해 정보의 성격을 빠르게 인지할 수 있게 합니다.

### Empty State Card

- 빈 상태는 부드럽고 친근하게 표현합니다.
- 연한 border 또는 dashed border를 사용할 수 있습니다.
- 부정적인 표현보다 다음 행동을 유도하는 문구를 사용합니다.
- 아이콘, 일러스트, 짧은 안내 문구, 보조 버튼을 조합할 수 있습니다.

---

## 8. Button Rules

### Primary Button

- Background: `#58BE82` or `#4FB879`
- Text: `#FFFFFF`
- Radius: 22~30px
- Height: 56~68px
- Font Size: 18~22px
- Font Weight: `w800`
- Width: 주요 CTA의 경우 full width 권장

### Secondary Button

- Background: `#FFFFFF`
- Border: `#DDE5EF`
- Text: `#344154` or `#738096`
- Radius: 22~30px

### Outline Button

- Background: transparent or white
- Border: Main Accent color
- Text: Main Accent color
- Radius: 22~30px

### Button Guidelines

- 한 화면에서 Primary Button은 1개를 중심으로 사용합니다.
- 버튼 텍스트는 짧고 명확한 동사형 문구를 사용합니다.
- 비활성 버튼은 opacity를 낮추거나 연한 회색 계열을 사용합니다.
- 버튼 내부 좌우 padding은 충분히 확보합니다.

---

## 9. Chip & Tag Rules

칩과 태그는 선택, 필터, 상태, 카테고리 표시 등에 사용합니다.

### Default Chip

- Background: `#F3F6FA`
- Text: `#344154`
- Radius: 999px
- Padding: horizontal 14~18px, vertical 8~12px
- Font Size: 13~15px

### Selected Chip

- Background: soft green or white
- Border: Main Accent color
- Text: Main Accent or Primary Text

### Status Tag

- 상태를 나타내는 태그는 작은 pill 형태를 사용합니다.
- 긍정 상태는 green 계열, 주의 상태는 red 계열, 보조 상태는 gray-blue 계열을 사용합니다.
- 태그는 과도하게 크지 않게 하며 정보 보조 역할로 사용합니다.

### Guidelines

- 칩은 2줄 이상 길어지지 않게 합니다.
- 이모지나 아이콘을 사용할 경우 텍스트 앞에 작게 배치합니다.
- 선택 가능한 칩과 단순 표시용 태그는 시각적으로 구분합니다.

---

## 10. Icon Rules

- 얇은 라인 아이콘을 기본으로 사용합니다.
- 필요에 따라 부드러운 이모지 스타일을 함께 사용할 수 있습니다.
- 아이콘은 너무 딱딱하거나 무겁지 않게 표현합니다.
- 아이콘 배경은 연한 회색 박스 `#F3F5FA`를 사용합니다.
- 활성 상태의 아이콘은 Main Accent 색상으로 강조합니다.
- 비활성 상태는 `#738096` 계열을 사용합니다.
- 아이콘 박스는 radius 18~24px를 적용합니다.

---

## 11. Navigation Rules

### Bottom Navigation

- 하단 고정 내비게이션을 사용할 수 있습니다.
- 배경은 `#FFFFFF`를 사용합니다.
- 상단에는 얇은 border line을 적용합니다.
- 높이는 78~88px를 권장합니다.
- 아이콘은 위, 라벨은 아래 구조를 권장합니다.
- 라벨은 12~14px 크기로 표시합니다.
- Active item은 Main Accent 색상을 사용합니다.
- Inactive item은 `#738096` 또는 연한 gray-blue를 사용합니다.

### Top Navigation

- 상단 영역은 간결하게 구성합니다.
- 좌측에는 화면 제목 또는 브랜드 영역을 배치할 수 있습니다.
- 우측에는 프로필, 알림, 설정, 보조 액션 등을 배치할 수 있습니다.
- 상단 버튼은 pill 형태를 권장합니다.

---

## 12. Image & Visual Placeholder Rules

- 실제 이미지가 없을 경우 gradient placeholder나 부드러운 추상 그래픽을 사용합니다.
- 이미지 썸네일은 radius 18~24px를 적용합니다.
- 이미지는 화면의 분위기를 해치지 않도록 채도가 낮고 밝은 톤을 사용합니다.
- 과도하게 사실적인 인물 이미지나 특정 브랜드를 연상시키는 이미지는 피합니다.
- placeholder는 단순한 색면보다 은은한 gradient, 아이콘, 패턴을 조합해 완성도를 높입니다.

---

## 13. Form & Input Rules

- 입력 필드는 둥근 모서리와 연한 배경을 사용합니다.
- Border는 `#DDE5EF`를 기본으로 사용합니다.
- Focus 상태에서는 Main Accent 색상으로 강조합니다.
- Placeholder는 Secondary Text보다 더 연한 색을 사용합니다.
- 입력 필드 높이는 52~60px를 권장합니다.
- 오류 메시지는 Warning / Alert 색상을 사용하되 문구는 부드럽게 작성합니다.

---

## 14. State Design Rules

### Loading State

- Skeleton UI 또는 부드러운 shimmer를 사용할 수 있습니다.
- 강한 로딩 스피너보다 화면 구조를 유지하는 skeleton 방식을 권장합니다.

### Empty State

- 빈 화면은 친근한 아이콘, 짧은 문구, 다음 행동 버튼으로 구성합니다.
- 사용자가 실패했다고 느끼지 않도록 긍정적이고 안내 중심으로 표현합니다.

### Error State

- 오류는 명확하지만 과하게 위협적이지 않게 표시합니다.
- 원인보다 사용자가 할 수 있는 다음 행동을 우선 안내합니다.
- 필요 시 재시도 버튼을 제공합니다.

### Success State

- 성공 상태는 Main Accent, 체크 아이콘, 짧은 긍정 문구로 표현합니다.
- 과도한 애니메이션이나 팝업은 피합니다.

---

## 15. Floating Action Rules

- 보조 액션이 필요한 경우 우측 하단에 floating button을 배치할 수 있습니다.
- Shape: circle 또는 pill
- Background: Main Accent 또는 green gradient
- Icon: white line icon
- Shadow: 약하게 적용
- 하단 내비게이션과 겹치지 않도록 충분한 bottom margin을 둡니다.

---

## 16. Motion & Interaction Rules

- 애니메이션은 빠르고 부드럽게 적용합니다.
- 화면 전환, 카드 등장, 버튼 피드백에는 150~300ms 정도의 짧은 motion을 사용합니다.
- 터치 피드백은 scale, opacity, ripple 중 하나를 과하지 않게 사용합니다.
- 복잡한 3D 효과, 과한 bounce, 강한 transition은 피합니다.
- 사용자가 행동 결과를 즉시 이해할 수 있도록 상태 변화를 명확히 보여줍니다.

---

## 17. Accessibility Rules

- 텍스트와 배경의 대비를 충분히 확보합니다.
- 터치 가능한 요소는 최소 44px 이상의 터치 영역을 확보합니다.
- 색상만으로 상태를 구분하지 않고 텍스트, 아이콘, 형태를 함께 사용합니다.
- 중요한 버튼과 안내 문구는 작은 글씨로 숨기지 않습니다.
- 주요 액션은 엄지 손가락이 닿기 쉬운 위치에 배치합니다.

---

## 18. Do & Don’t

### Do

- 부드러운 배경과 흰색 카드 중심으로 구성합니다.
- 큰 radius와 넉넉한 padding을 사용합니다.
- 정보는 카드 단위로 명확하게 나눕니다.
- 주요 CTA는 한 화면에서 가장 눈에 띄게 배치합니다.
- 강조 색상은 제한적으로 사용합니다.
- 빈 상태와 오류 상태도 완성된 화면처럼 디자인합니다.

### Don’t

- 특정 서비스명, 기능명, 도메인 명칭을 디자인 규칙에 포함하지 않습니다.
- 특정 화면 구조에 종속된 규칙을 작성하지 않습니다.
- 강한 그림자, 진한 border, 과한 gradient를 사용하지 않습니다.
- 너무 많은 색상과 폰트 크기를 한 화면에 섞지 않습니다.
- 각진 UI, 빽빽한 레이아웃, 작은 터치 영역을 사용하지 않습니다.
- 실제 브랜드 이미지, 로고, 캐릭터, 고유 시각 자산을 그대로 참조하지 않습니다.

---

## 19. Reusable Design Token Summary

```text
Background:        #F2F5FA / #F4F7FB
Surface:           #FFFFFF
Primary Accent:    #58BE82
Active Accent:     #4FB879
Soft Mint:         #E6F4F0
Soft Blue:         #EAF2FA
Primary Text:      #344154
Secondary Text:    #738096
Border:            #DDE5EF
Divider:           #E8EDF3
Warning:           #F05A4A
Point Yellow:      #FFE177
Purple Accent:     #C982F2

Screen Padding:    20~24px
Section Gap:       28~40px
Card Padding:      20~28px
Card Radius:       24~32px
Large Radius:      32~40px
Button Height:     56~68px
Button Radius:     22~30px
Chip Radius:       999px
Icon Box Radius:   18~24px
```

---

## 20. Final Principle

이 디자인 시스템의 핵심은 **부드러움, 명확함, 안정감, 재사용성**입니다.

어떤 서비스에 적용하더라도 특정 기획에 끌려가지 않고, 따뜻하고 프리미엄한 모바일 UI 분위기를 유지하는 것을 목표로 합니다.
