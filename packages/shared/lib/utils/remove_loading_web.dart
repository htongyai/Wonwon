import 'dart:html' as html;

void removeHtmlLoadingElement() {
  final loading = html.document.getElementById('loading');
  if (loading != null) {
    loading.style.opacity = '0';
    loading.style.transition = 'opacity 0.3s ease-out';
    Future.delayed(const Duration(milliseconds: 300), () {
      loading.remove();
    });
  }
}
