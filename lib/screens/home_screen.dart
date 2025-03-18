import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/custom_footer.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          // Move content up slightly using Transform.translate
          Center(
            child: Transform.translate(
              offset: Offset(0, -30), // Moves up by 30 pixels
              child: Card(
                elevation: 10,
                shadowColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.black,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image inside Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/bgnu.jpeg',
                          width: 250,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),

                      SizedBox(height: 15),

                      // Heading
                      Text(
                        "About Baba Guru Nanak University",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),

                      SizedBox(height: 10),

                      // Explanation Text
                      Text(
                        "Baba Guru Nanak University (BGNU) is a prestigious institution committed to excellence in education, research, and innovation. It aims to provide world-class learning opportunities in various disciplines while promoting cultural heritage and academic excellence.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomFooter(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
