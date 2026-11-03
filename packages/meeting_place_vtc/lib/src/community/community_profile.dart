/// What a community's governance asserts about its members' personhood.
class CommunityPersonhood {
  /// Creates a [CommunityPersonhood].
  const CommunityPersonhood({
    this.realHuman = false,
    this.singleMembership = false,
    this.governanceFrameworkUrl,
  });

  /// Members must be real humans.
  final bool realHuman;

  /// Each person holds at most one membership of the community.
  final bool singleMembership;

  /// Where the governance framework behind these assertions can be read.
  final Uri? governanceFrameworkUrl;
}

/// What a community publishes about itself to anyone
/// (`GET <base>/community/public-profile`).
///
/// Unlike the join manifest it is not signed: it is only as sound as the
/// HTTPS connection to the endpoint the community's DID document names.
class CommunityProfile {
  /// Creates a [CommunityProfile].
  const CommunityProfile({
    required this.communityDid,
    this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.contactEmail,
    this.personhood = const CommunityPersonhood(),
  });

  /// The community's DID.
  final String communityDid;

  /// The community's name.
  final String? name;

  /// What the community is about, in its own words.
  final String? description;

  /// The community's logo, if an `https` one.
  final Uri? logoUrl;

  /// The community's website, if an `https` one.
  final Uri? website;

  /// Where to write to the community.
  final String? contactEmail;

  /// What the community asserts about its members' personhood.
  final CommunityPersonhood personhood;
}
