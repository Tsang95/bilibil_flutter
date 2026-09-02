import 'package:b_flutter/models/post_summary.dart';

enum PostDetailLoadingLayout {
  generic,
  standard,
  immersiveVideo,
  forum,
  mangaCollection,
  mangaReader,
}

final class PostDetailRouteArguments {
  const PostDetailRouteArguments({
    required this.loadingLayout,
    this.showPlayerPlaceholder = false,
    this.showContentPlaceholder = false,
    this.horizontalCover = false,
  });

  const PostDetailRouteArguments.generic()
      : loadingLayout = PostDetailLoadingLayout.generic,
        showPlayerPlaceholder = true,
        showContentPlaceholder = false,
        horizontalCover = false;

  factory PostDetailRouteArguments.fromSummary(PostSummary post) {
    return PostDetailRouteArguments.fromMetadata(
      type: post.type,
      collectionType: post.collectionType,
      primaryCategoryId: post.primaryCategoryId,
      hasCover: post.coverUrls.isNotEmpty,
      hasHorizontalCover: post.horizontalCoverUrls.isNotEmpty,
      hasDescription: post.description.trim().isNotEmpty,
    );
  }

  factory PostDetailRouteArguments.fromMetadata({
    required int type,
    required int collectionType,
    required int primaryCategoryId,
    bool hasCover = false,
    bool hasHorizontalCover = false,
    bool hasDescription = false,
  }) {
    final videoType =
        type == 0 || type == 1 || type == 3 || collectionType == 1;
    if (type == 5) {
      return PostDetailRouteArguments(
        loadingLayout: collectionType == 1
            ? PostDetailLoadingLayout.mangaCollection
            : PostDetailLoadingLayout.mangaReader,
        showContentPlaceholder: collectionType != 1,
        horizontalCover: hasHorizontalCover,
      );
    }
    if (primaryCategoryId == 83) {
      return PostDetailRouteArguments(
        loadingLayout: PostDetailLoadingLayout.forum,
        showPlayerPlaceholder: videoType || (type != 2 && hasCover),
        showContentPlaceholder: type == 2 || hasDescription,
        horizontalCover: hasHorizontalCover,
      );
    }
    if (type == 1 || collectionType == 1) {
      return PostDetailRouteArguments(
        loadingLayout: PostDetailLoadingLayout.immersiveVideo,
        showPlayerPlaceholder: true,
        horizontalCover: hasHorizontalCover,
      );
    }
    return PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.standard,
      showPlayerPlaceholder: videoType || (type != 2 && hasCover),
      showContentPlaceholder: type == 2 ||
          hasDescription ||
          (!videoType && (type == 4 || !hasCover)),
      horizontalCover: hasHorizontalCover,
    );
  }

  final PostDetailLoadingLayout loadingLayout;
  final bool showPlayerPlaceholder;
  final bool showContentPlaceholder;
  final bool horizontalCover;
}
