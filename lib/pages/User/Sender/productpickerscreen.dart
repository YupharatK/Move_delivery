import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({super.key});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  final Map<String, int> _qty = {}; // qty ต่อสินค้า
  static const _pageSize = 30;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  Query<Map<String, dynamic>> _baseQuery() => FirebaseFirestore.instance
      .collection('products')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      )
      .orderBy(FieldPath.documentId)
      .limit(_pageSize);

  @override
  void initState() {
    super.initState();
    _fetchFirst();
  }

  Future<void> _fetchFirst() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    try {
      final snap = await _baseQuery().get(
        const GetOptions(source: Source.server),
      );
      _docs.addAll(snap.docs);
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      if (snap.docs.length < _pageSize) _hasMore = false;
      _sortByNameClient();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final q = (_lastDoc == null)
          ? _baseQuery()
          : _baseQuery().startAfterDocument(_lastDoc!);
      final snap = await q.get(const GetOptions(source: Source.server));
      if (snap.docs.isNotEmpty) {
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.last;
        _sortByNameClient();
      }
      if (snap.docs.length < _pageSize) _hasMore = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดเพิ่มไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _sortByNameClient() {
    _docs.sort((a, b) {
      final na = (a.data()['name'] ?? '').toString().toLowerCase().trim();
      final nb = (b.data()['name'] ?? '').toString().toLowerCase().trim();
      if (na.isEmpty && nb.isEmpty) return 0;
      if (na.isEmpty) return 1;
      if (nb.isEmpty) return -1;
      return na.compareTo(nb);
    });
  }

  void _inc(String id) => setState(() => _qty[id] = (_qty[id] ?? 1) + 1);
  void _dec(String id) =>
      setState(() => _qty[id] = ((_qty[id] ?? 1) - 1).clamp(1, 999999));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกสินค้า (ไม่ auto-reload)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchFirst),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('โหลดสินค้าไม่สำเร็จ\n$_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchFirst,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }
    if (_docs.isEmpty) return const Center(child: Text('ยังไม่มีสินค้า'));

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification) {
          final m = n.metrics;
          if (m.pixels >= m.maxScrollExtent - 200) _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.74,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _docs.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (_hasMore && i == _docs.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = _docs[i];
          final data = doc.data();
          final id = doc.id;

          final name = (data['name'] ?? '-').toString();
          final desc = (data['description'] ?? '').toString();
          final img = (data['imageUrl'] ?? '').toString();

          // ✨ กันชนราคา -> double แน่นอน
          final raw = data['price'];
          final price = (raw is num)
              ? raw.toDouble()
              : double.tryParse('${raw ?? ''}') ?? 0.0;

          final qty = _qty[id] ?? 1;

          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: img.isNotEmpty
                      ? Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${price.toStringAsFixed(2)} ฿',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _QtyStepper(
                                value: qty,
                                onAdd: () => _inc(id),
                                onRemove: qty > 1 ? () => _dec(id) : null,
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    // ✨ ส่งค่าที่ฝั่งรายละเอียดต้องใช้ครบเสมอ
                                    Navigator.pop(context, {
                                      'productId': id,
                                      'name': name,
                                      'description': desc,
                                      'imageUrl': img,
                                      'price': price, // double ชัวร์
                                      'qty': qty, // int ชัวร์
                                    });
                                  },
                                  child: const Text('เลือก'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _imgFallback() => Container(
    color: Colors.grey[200],
    child: const Center(child: Icon(Icons.image, size: 40)),
  );
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onAdd,
    required this.onRemove,
  });
  final int value;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconBtn(icon: Icons.remove, onPressed: onRemove),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        _RoundIconBtn(icon: Icons.add, onPressed: onAdd),
      ],
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
