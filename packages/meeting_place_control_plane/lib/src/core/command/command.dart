abstract class DiscoveryCommand<T> {
  bool get requiresBootstrap => true;

  bool get requiresAuthentication => true;
}
