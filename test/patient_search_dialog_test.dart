import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/models/patient_model.dart';
import 'package:medecat_research/screens/sections/patient_search_dialog.dart';

void main() {
  final samplePatients = [
    PatientModel(
      patientId: 'pat-1',
      medicalRecordNumber: 'MRN-101',
      demographics: {
        'name': 'Ahmed Ali',
        'age': 32,
        'phone': '01011122233',
        'gender': 'Male',
      },
      createdAt: DateTime.now(),
    ),
    PatientModel(
      patientId: 'pat-2',
      medicalRecordNumber: 'MRN-102',
      demographics: {
        'name': 'Fatima Mahmoud',
        'age': 28,
        'phone': '01144455566',
        'gender': 'Female',
      },
      createdAt: DateTime.now(),
    ),
    PatientModel(
      patientId: 'pat-3',
      medicalRecordNumber: 'MRN-103',
      demographics: {
        'name': 'Omar Hassan',
        'age': 45,
        'phone': '01277788899',
        'gender': 'Male',
      },
      createdAt: DateTime.now(),
    ),
  ];

  testWidgets('PatientSearchDialog renders without overflow on small screens and filters correctly', (WidgetTester tester) async {
    // Simulate a small screen (e.g., 360x640 mobile phone)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    PatientModel? selectedPatient;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                openPatientSearchDialog(
                  context: ctx,
                  patients: samplePatients,
                  selectedPatient: null,
                  onPatientSelected: (pat) {
                    selectedPatient = pat;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog title & search field
    expect(find.text('Select Patient'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Fatima Mahmoud'), findsOneWidget);
    expect(find.text('Omar Hassan'), findsOneWidget);

    // Filter by name
    await tester.enterText(find.byType(TextField), 'Fatima');
    await tester.pumpAndSettle();

    expect(find.text('Fatima Mahmoud'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsNothing);
    expect(find.text('Omar Hassan'), findsNothing);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Fatima Mahmoud'), findsOneWidget);

    // Filter by MRN
    await tester.enterText(find.byType(TextField), '103');
    await tester.pumpAndSettle();

    expect(find.text('Omar Hassan'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsNothing);

    // Select Omar
    await tester.tap(find.text('Omar Hassan'));
    await tester.pumpAndSettle();

    // Verify dialog dismissed and callback received selected patient
    expect(find.text('Select Patient'), findsNothing);
    expect(selectedPatient?.patientId, equals('pat-3'));
  });

  testWidgets('PatientSearchDialog handles on-screen keyboard without RenderFlex overflow (overload)', (WidgetTester tester) async {
    // 360x640 mobile screen with 280px keyboard inset
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                openPatientSearchDialog(
                  context: ctx,
                  patients: samplePatients,
                  selectedPatient: null,
                  onPatientSelected: (_) {},
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify dialog is open and visible above keyboard with NO exception
    expect(find.text('Select Patient'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Select Patient'), findsNothing);
  });

  testWidgets('PatientSearchDialog performs seamlessly on large datasets without lag', (WidgetTester tester) async {
    final largePatientList = List.generate(
      500,
      (i) => PatientModel(
        patientId: 'pat-$i',
        medicalRecordNumber: 'MRN-${1000 + i}',
        demographics: {
          'name': 'Patient $i',
          'age': 20 + (i % 50),
          'phone': '0100000$i',
        },
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                openPatientSearchDialog(
                  context: ctx,
                  patients: largePatientList,
                  selectedPatient: null,
                  onPatientSelected: (_) {},
                );
              },
              child: const Text('Open Large List'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Large List'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 500 of 500 patients'), findsOneWidget);

    // Search for patient 444
    await tester.enterText(find.byType(TextField), '444');
    await tester.pumpAndSettle();

    expect(find.text('Patient 444'), findsOneWidget);
    expect(find.text('Showing 1 of 500 patients'), findsOneWidget);
  });
}
