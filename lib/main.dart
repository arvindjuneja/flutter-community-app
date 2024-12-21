import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/services.dart';
import 'view_models/view_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(
          create: (_) => FirebaseService(),
        ),
        Provider(
          create: (context) => AuthService(
            firestore: context.read<FirebaseService>().firestore,
            auth: context.read<FirebaseService>().auth,
            storage: context.read<FirebaseService>().storage,
          ),
        ),
        Provider(
          create: (context) => NewsService(
            firestore: context.read<FirebaseService>().firestore,
            auth: context.read<FirebaseService>().auth,
            storage: context.read<FirebaseService>().storage,
          ),
        ),
        Provider(
          create: (context) => HydeParkService(
            firestore: context.read<FirebaseService>().firestore,
            auth: context.read<FirebaseService>().auth,
            storage: context.read<FirebaseService>().storage,
          ),
        ),
        Provider(
          create: (context) => BusinessService(
            firestore: context.read<FirebaseService>().firestore,
            auth: context.read<FirebaseService>().auth,
            storage: context.read<FirebaseService>().storage,
          ),
        ),
        Provider(
          create: (context) => CommentService(
            firestore: context.read<FirebaseService>().firestore,
            auth: context.read<FirebaseService>().auth,
            storage: context.read<FirebaseService>().storage,
          ),
        ),
        
        // View Models
        ChangeNotifierProvider(
          create: (context) => UserViewModel(
            context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NewsViewModel(
            context.read<NewsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HydeParkViewModel(
            context.read<HydeParkService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BusinessViewModel(
            context.read<BusinessService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CommentViewModel(
            context.read<CommentService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Community App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Schedule')),
    const Center(child: Text('Hyde Park')),
    const Center(child: Text('Directory')),
    const Center(child: Text('Profile')),
  ];

  final List<String> _titles = [
    'News Feed',
    'Schedule',
    'Hyde Park',
    'Directory',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Hyde Park',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Directory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}