class Sponsor {
  final int id;
  final String category;
  final String image;

  Sponsor({required this.id, required this.category, required this.image});

  factory Sponsor.fromSupabase(Map<String, dynamic> data) {
    return Sponsor(
      id: data['id'],
      category: data['category'],
      image: data['image'],
    );
  }
}
