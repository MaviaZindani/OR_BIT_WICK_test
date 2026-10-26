# Product Explorer

A small Flutter app that browses, searches and filters a product catalogue
from the public [DummyJSON](https://dummyjson.com/docs/products) API. Built as
a practical test assignment; runs on Android and iOS.

- Flutter 3.41 · Dart 3.11
- State management: `flutter_bloc` + `bloc_concurrency`
- No API key needed - DummyJSON is open

## Features

| Area | What it does |
|---|---|
| Browse | Paged product grid (20 per page) with infinite scroll and pull-to-refresh |
| Search | Live search with a 350ms debounce; stale responses are discarded |
| Filter | Category chips (24 categories from the API) + a sort sheet (price ↑↓, rating, name) |
| Detail | Swipeable photo gallery with a Hero from the grid, price / discount / stock, specs, reviews |
| Errors | Typed exceptions with the server's own message, retry on every failure, no-internet and timeout text, a failed *page 2* keeps page 1 and shows an inline retry, a failed refresh keeps the grid and shows a snackbar, a failed category fetch leaves the grid working |
| Layout | 2 / 3 / 4 grid columns by width; the detail screen goes side-by-side from 700dp |

## Downloads

Release builds are attached to the
[Releases page](https://github.com/MaviaZindani/OR_BIT_WICK_test/releases):
`ProductExplorer-release.apk` installs directly on Android. The iOS build is
unsigned (no Apple Developer team on this machine), so it runs from source on
a simulator; a signed build can be provided through TestFlight on request.

## Running

```bash
flutter pub get
flutter run            # pick a device / simulator
flutter test           # 34 tests
flutter analyze
```

## Architecture

```
lib/
├── models/              ProductModel, ProductPage, CategoryModel, ProductDetailModel, ReviewModel
├── service/api_service/ ApiService (http), ApiLinks (urls), AppHost (headers / messages), ApiExceptions
├── api_controller/      one per screen - json → models
│   ├── api_guard.dart                    ApiGuard mixin, wraps every call
│   ├── product_api_controller.dart       Explore: list, category, search, categories
│   └── product_detail_api_controller.dart
├── bloc/                each: <feature>_bloc.dart + _event.dart + _state.dart
│   ├── products/        ProductsBloc       - flat state; restartable search, droppable paging
│   └── product_detail/  ProductDetailBloc  - sealed states
├── generic_widgets/     ProductCard, CategoryChip, RatingBadge, AppSearchField,
│                        AppNetworkImage, PrimaryButton, loader / error / empty views
├── view/                screens, one folder per feature, widgets/ beneath each
├── routes/              RouteGenerator + AppRoutes
├── arguments/           typed route arguments
├── enums/               ProductSort (label + server query params), environment flavour
├── constant/            AppColors, DataConst, AppTextStyles
└── utils/               HelperFunction (price / date / count formatting), ScreenHelper
```

### Decisions

**Layers.** `ApiService` only knows how to make a request and turn a status
code into a typed `ApiExceptions`. An *api controller* per screen turns json
into models, so a bloc never sees a `Map`. Blocs hold state and sequencing.
Views are thin: they dispatch events and `switch` on state. Each layer can be
swapped or tested without the one above it - the controller tests run against
an `http` `MockClient`, the bloc tests against stub controllers, the screen
tests against stub controllers with no network at all.

**One bloc for browse, search and filter.** Query, category and sort are three
inputs to one list, so they live in one `ProductsState` rather than three
blocs that would have to be kept in step. The state is flat (status enums +
fields) instead of a sealed hierarchy because the category row and the grid
are concurrent: categories load once and must survive every keystroke, chip
tap and page load that replaces the products. The detail bloc *is* sealed -
one request, one outcome - so the view gets an exhaustive `switch`.

**Concurrency is handled with `bloc_concurrency` transformers, not flags.**
`restartable()` on the search event gives the debounce (the handler sleeps
350ms, and a new keystroke cancels it before any request is made) and kills an
older in-flight search. `droppable()` on load-more ignores scroll events while
a page is in flight instead of queueing them. Because `restartable()` only
cancels handlers of the *same* event type, every fetch also snapshots the
filters it was made for and drops its response if the user has moved on - the
case where a chip tap lands while a search is still running is a test.

**Search + category.** DummyJSON's `/products/search` cannot be scoped to a
category, and paging through server results while hiding the ones outside the
chosen category would produce pages of nothing. So search mode asks for every
match at once (`limit=0`), applies the category locally and disables paging;
browse mode pages through the server (`/products` or
`/products/category/{slug}`). The whole catalogue is under 200 rows and every
list request uses `select=` to trim each row to the ten fields the grid
renders, so the full match set is still a small payload. The header count is
always the server's `total` (or the local count after filtering), never
`products.length`, which caps at a page.

**Errors carry the server's wording.** `ApiService` lifts DummyJSON's
`message` field into the exception (`Product with id '999' not found`), and
`ApiGuard` catches anything thrown *after* the response - a payload in the
wrong shape - so a `TypeError` never reaches the error view. Which failures
degrade and which block is decided per case: a failed first page blocks
(error view + retry); a failed next page, refresh or category fetch does not
(inline retry, snackbar, hidden chip row).

**Blocs are created in the route, not in `main`.** Each screen's bloc is
disposed with its route rather than outliving the screen with stale data.
Only the api controllers are app-wide (`RepositoryProvider`), and they are
stateless. Navigation uses typed argument classes so a wrong payload is a
compile error, not a runtime cast.

**Images.** `Image.network` with Flutter's built-in `ImageCache` rather than
`cached_network_image`, which pulls in path_provider / sqflite for a disk
cache that scrolling a 200-row catalogue does not need. The detail screen
paints the tapped card's thumbnail (and title) immediately from the route
arguments while the detail request runs.

## Tests

| File | Covers |
|---|---|
| `test/api_controller_test.dart` | Url / query building, `select` + sort params, local category filter in search mode, 404 / 500 / connection-failure / malformed-payload mapping |
| `test/bloc_test.dart` | Pagination merge + de-dupe, failed page 2, dropped scroll events, debounce, stale-response guard, cross-event race, clear search / filters, refresh failure modes, detail retry |
| `test/screens_test.dart` | Grid + chips + count, discount badge / out-of-stock, error → retry, empty → clear filters, card → detail, detail content, wide layout |
| `test/widget_test.dart` | Splash → Explore boot, model parsing edge cases |
