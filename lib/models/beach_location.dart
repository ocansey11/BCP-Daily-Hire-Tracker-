enum BeachLocation {
  bournemouth,
  alumChine,
  branksomeDeneChine,
  branksomeChine,
  durleyChine,
  boscombe,
  southbourne,
  fishermansWalk,
  canfordCliffs,
  shoreRoad,
  sandbanks;

  String get displayName {
    switch (this) {
      case BeachLocation.bournemouth:
        return 'Bournemouth';
      case BeachLocation.alumChine:
        return 'Alum Chine';
      case BeachLocation.branksomeDeneChine:
        return 'Branksome Dene Chine';
      case BeachLocation.branksomeChine:
        return 'Branksome Chine';
      case BeachLocation.durleyChine:
        return 'Durley Chine';
      case BeachLocation.boscombe:
        return 'Boscombe';
      case BeachLocation.southbourne:
        return 'Southbourne';
      case BeachLocation.fishermansWalk:
        return "Fisherman's Walk";
      case BeachLocation.canfordCliffs:
        return 'Canford Cliffs';
      case BeachLocation.shoreRoad:
        return 'Shore Road';
      case BeachLocation.sandbanks:
        return 'Sandbanks';
    }
  }

  String get id => name;

  static BeachLocation fromId(String id) {
    return BeachLocation.values.firstWhere((e) => e.name == id);
  }
}
