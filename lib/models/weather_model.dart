class WeatherModel {
  final double temperature;
  final double feelsLike;
  final String condition;
  final List<String> descriptions;
  final int humidity;
  final double windSpeed;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.descriptions,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      condition: json['weather'][0]['main'],
      descriptions: List<String>.from(
          json['weather'].map((w) => w['description'].toString())),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
}
