import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetStorage _storage = GetStorage();
  JourneyDetails? journeyDetails;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchJourneyDetails();
  }

  Future<void> _fetchJourneyDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final String? train_number = "17221";
      if (train_number == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse(
          'https://rail-madad-otq2.onrender.com/complaint/get-user-journey/?train_number=$train_number',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          journeyDetails = JourneyDetails.fromJson(responseData);
          isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load journey details: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading journey details: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: const Color(0xff6A8DFF),
        title: Text(
          "Rail Madat",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchJourneyDetails,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Journey Details",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(color: Colors.black, thickness: 1),

              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (journeyDetails == null)
                const Expanded(
                  child: Center(child: Text("No journey details found")),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Train Information
                        _buildInfoCard(
                          title: 'Train Information',
                          children: [
                            _buildInfoRow(
                              'Train Name',
                              journeyDetails!.trainName,
                            ),
                            _buildInfoRow(
                              'Train Number',
                              journeyDetails!.trainNumber,
                            ),
                            _buildInfoRow(
                              'Manager',
                              journeyDetails!.trainManagerName,
                            ),
                            _buildInfoRow(
                              'Manager Contact',
                              journeyDetails!.trainManagerNumber,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Department Contacts
                        Text(
                          "Department Contacts",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDepartmentContacts(
                          journeyDetails!.departmentDetails,
                        ),

                        const SizedBox(height: 16),

                        // Complaints Section
                        Text(
                          "Your Complaints",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (journeyDetails!.complaints.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No complaints filed yet"),
                          )
                        else
                          Column(
                            children:
                                journeyDetails!.complaints
                                    .map(
                                      (complaint) => ComplaintCard(
                                        complaint: complaint,
                                        onStatusUpdate: (newStatus) {
                                          setState(() {
                                            complaint.status = newStatus;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add navigation to complaint filing page
        },
        backgroundColor: const Color(0xff6A8DFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDepartmentContacts(DepartmentDetails departments) {
    return Column(
      children: [
        _buildDepartmentTile('Medical', departments.medical),
        _buildDepartmentTile('Electrical', departments.electrical),
        _buildDepartmentTile('Security', departments.security),
        _buildDepartmentTile('Emergency', departments.emergency),
        _buildDepartmentTile('General Staff', departments.generalStaff),
      ],
    );
  }

  Widget _buildDepartmentTile(String title, Department department) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Head: ${department.head}'),
            Text('Contact: ${department.headNumber}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // Implement call functionality
          },
        ),
      ),
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final Function(String) onStatusUpdate;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onStatusUpdate,
  });

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Hardcoded data as per requirements
      final Map<String, dynamic> requestData = {
        "manager_id": "manager harish_2d95a5",
        "complaint_id": complaint.complaintId,
        "status_to_set": newStatus,
      };

      final response = await http.post(
        Uri.parse('https://rail-madad-otq2.onrender.com/manager/set_status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      Navigator.of(context).pop(); // Dismiss loading indicator

      if (response.statusCode == 200) {
        // Call the callback to update the UI
        onStatusUpdate(newStatus);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${response.body}')),
        );
      }
    } catch (e) {
      // Navigator.of(context).pop(); // Dismiss loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Complaint Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Resolved'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(context, 'resolved');
                  },
                ),
                ListTile(
                  title: const Text('In Progress'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(context, 'in progress');
                  },
                ),
                ListTile(
                  title: const Text('Reported'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(context, 'reported');
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (complaint.status.toLowerCase()) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'in progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  complaint.complaintType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complaint ID: ${complaint.complaintId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class JourneyDetails {
  final String trainName;
  final String trainNumber;
  final String trainManagerName;
  final String trainManagerNumber;
  final String managerId;
  final DepartmentDetails departmentDetails;
  final List<Complaint> complaints;

  JourneyDetails({
    required this.trainName,
    required this.trainNumber,
    required this.trainManagerName,
    required this.trainManagerNumber,
    required this.managerId,
    required this.departmentDetails,
    required this.complaints,
  });

  factory JourneyDetails.fromJson(Map<String, dynamic> json) {
    return JourneyDetails(
      trainName: json['train_name'] ?? 'Unknown Train',
      trainNumber: json['train_number'] ?? 'N/A',
      trainManagerName: json['train_manager_name'] ?? 'Unknown Manager',
      trainManagerNumber: json['train_manager_number'] ?? 'N/A',
      managerId: json['manager_id'] ?? 'N/A',
      departmentDetails: DepartmentDetails.fromJson(
        json['department_details'] ?? {},
      ),
      complaints:
          (json['complaints'] as List<dynamic>?)
              ?.map((e) => Complaint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DepartmentDetails {
  final Department medical;
  final Department electrical;
  final Department security;
  final Department emergency;
  final Department generalStaff;

  DepartmentDetails({
    required this.medical,
    required this.electrical,
    required this.security,
    required this.emergency,
    required this.generalStaff,
  });

  factory DepartmentDetails.fromJson(Map<String, dynamic> json) {
    return DepartmentDetails(
      medical: Department.fromJson(json['medical'] ?? {}),
      electrical: Department.fromJson(json['electrical'] ?? {}),
      security: Department.fromJson(json['security'] ?? {}),
      emergency: Department.fromJson(json['emergency'] ?? {}),
      generalStaff: Department.fromJson(json['general_staff'] ?? {}),
    );
  }
}

class Department {
  final String head;
  final String headNumber;

  Department({required this.head, required this.headNumber});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      head: json['head'] ?? 'N/A',
      headNumber: json['head_number'] ?? 'N/A',
    );
  }
}

class Complaint {
  final String complaintId;
  final String complaintType;
  String status;

  Complaint({
    required this.complaintId,
    required this.complaintType,
    required this.status,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      complaintId: json['compliant_id'] ?? 'N/A',
      complaintType: json['complaint_type'] ?? 'Unknown',
      status: json['status'] ?? 'Reported',
    );
  }
}
