/// Temporary QA switch requested while the creator publishing flow is tested.
/// Set this back to `false` when the UP membership gate should be restored.
abstract final class CreatorAccessPolicy {
  static const bool allowPublishingWithoutVip = false;
}
