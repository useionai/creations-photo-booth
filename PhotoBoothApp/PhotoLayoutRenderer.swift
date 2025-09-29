import UIKit
import CoreGraphics

class PhotoLayoutRenderer {
    static let shared = PhotoLayoutRenderer()
    
    private init() {}
    
    // MARK: - Layout Generation
    
    func generatePreview(format: PhotoFormat, eventName: String, eventDate: String) -> UIImage {
        let previewSize = CGSize(width: 300, height: 400)
        
        switch format {
        case .singlePhoto:
            return generateSinglePhotoPreview(size: previewSize)
        case .singlePhotoWithDetails:
            return generateSinglePhotoWithDetailsPreview(size: previewSize, eventName: eventName, eventDate: eventDate)
        case .largePlusThreeSmall:
            return generateLargePlusThreeSmallPreview(size: previewSize, eventName: eventName, eventDate: eventDate)
        }
    }
    
    func generateLayout(format: PhotoFormat, photos: [UIImage], eventName: String, eventDate: String) -> UIImage {
        let outputSize = CGSize(width: 1200, height: 1800) // 4x6 inch at 300 DPI
        
        switch format {
        case .singlePhoto:
            return generateSinglePhotoLayout(photos: photos, size: outputSize)
        case .singlePhotoWithDetails:
            return generateSinglePhotoWithDetailsLayout(photos: photos, size: outputSize, eventName: eventName, eventDate: eventDate)
        case .largePlusThreeSmall:
            return generateLargePlusThreeSmallLayout(photos: photos, size: outputSize, eventName: eventName, eventDate: eventDate)
        }
    }
    
    // MARK: - Preview Generation
    
    private func generateSinglePhotoPreview(size: CGSize) -> UIImage {
        return generateImageWithText(size: size, backgroundColor: .systemBlue.withAlphaComponent(0.3)) { context, rect in
            // Draw placeholder photo
            let photoRect = CGRect(x: 20, y: 20, width: rect.width - 40, height: rect.height - 40)
            context.setFillColor(UIColor.systemGray4.cgColor)
            context.fill(photoRect)
            
            // Draw photo icon
            let iconSize: CGFloat = 60
            let iconRect = CGRect(
                x: photoRect.midX - iconSize/2,
                y: photoRect.midY - iconSize/2,
                width: iconSize,
                height: iconSize
            )
            drawCameraIcon(in: context, rect: iconRect)
        }
    }
    
    private func generateSinglePhotoWithDetailsPreview(size: CGSize, eventName: String, eventDate: String) -> UIImage {
        return generateImageWithText(size: size, backgroundColor: .systemGreen.withAlphaComponent(0.3)) { context, rect in
            // Draw placeholder photo
            let photoRect = CGRect(x: 20, y: 20, width: rect.width - 40, height: rect.height * 0.7)
            context.setFillColor(UIColor.systemGray4.cgColor)
            context.fill(photoRect)
            
            // Draw photo icon
            let iconSize: CGFloat = 50
            let iconRect = CGRect(
                x: photoRect.midX - iconSize/2,
                y: photoRect.midY - iconSize/2,
                width: iconSize,
                height: iconSize
            )
            drawCameraIcon(in: context, rect: iconRect)
            
            // Draw text area
            let textRect = CGRect(x: 20, y: photoRect.maxY + 10, width: rect.width - 40, height: rect.height * 0.25)
            context.setFillColor(UIColor.systemBackground.cgColor)
            context.fill(textRect)
            
            // Draw event details
            drawText(eventName, in: context, rect: CGRect(x: textRect.minX + 10, y: textRect.minY + 10, width: textRect.width - 20, height: 20), fontSize: 14, color: .label)
            drawText(eventDate, in: context, rect: CGRect(x: textRect.minX + 10, y: textRect.minY + 35, width: textRect.width - 20, height: 20), fontSize: 12, color: .secondaryLabel)
        }
    }
    
    private func generateLargePlusThreeSmallPreview(size: CGSize, eventName: String, eventDate: String) -> UIImage {
        return generateImageWithText(size: size, backgroundColor: .systemOrange.withAlphaComponent(0.3)) { context, rect in
            let margin: CGFloat = 10
            let spacing: CGFloat = 5
            
            // Large photo (top half)
            let largePhotoRect = CGRect(x: margin, y: margin, width: rect.width - 2*margin, height: rect.height * 0.5)
            context.setFillColor(UIColor.systemGray4.cgColor)
            context.fill(largePhotoRect)
            
            // Large photo icon
            let largeIconSize: CGFloat = 40
            let largeIconRect = CGRect(
                x: largePhotoRect.midX - largeIconSize/2,
                y: largePhotoRect.midY - largeIconSize/2,
                width: largeIconSize,
                height: largeIconSize
            )
            drawCameraIcon(in: context, rect: largeIconRect)
            
            // Three small photos (bottom left)
            let smallPhotoHeight: CGFloat = (rect.height * 0.4 - 2*spacing) / 3
            let smallPhotoWidth: CGFloat = rect.width * 0.6 - margin - spacing/2
            
            for i in 0..<3 {
                let y = largePhotoRect.maxY + spacing + CGFloat(i) * (smallPhotoHeight + spacing)
                let smallPhotoRect = CGRect(x: margin, y: y, width: smallPhotoWidth, height: smallPhotoHeight)
                context.setFillColor(UIColor.systemGray5.cgColor)
                context.fill(smallPhotoRect)
                
                // Small photo icon
                let smallIconSize: CGFloat = 20
                let smallIconRect = CGRect(
                    x: smallPhotoRect.midX - smallIconSize/2,
                    y: smallPhotoRect.midY - smallIconSize/2,
                    width: smallIconSize,
                    height: smallIconSize
                )
                drawCameraIcon(in: context, rect: smallIconRect)
            }
            
            // Text area (bottom right)
            let textAreaRect = CGRect(
                x: margin + smallPhotoWidth + spacing,
                y: largePhotoRect.maxY + spacing,
                width: rect.width * 0.4 - margin - spacing/2,
                height: rect.height * 0.4
            )
            context.setFillColor(UIColor.systemBackground.cgColor)
            context.fill(textAreaRect)
            
            // Draw event details
            drawText(eventName, in: context, rect: CGRect(x: textAreaRect.minX + 5, y: textAreaRect.minY + 10, width: textAreaRect.width - 10, height: 20), fontSize: 10, color: .label)
            drawText(eventDate, in: context, rect: CGRect(x: textAreaRect.minX + 5, y: textAreaRect.minY + 35, width: textAreaRect.width - 10, height: 20), fontSize: 8, color: .secondaryLabel)
        }
    }
    
    // MARK: - Layout Generation
    
    private func generateSinglePhotoLayout(photos: [UIImage], size: CGSize) -> UIImage {
        guard let photo = photos.first else {
            return generatePlaceholderImage(size: size, text: "No Photo")
        }
        
        return generateImageWithText(size: size, backgroundColor: .white) { context, rect in
            let photoRect = rect.insetBy(dx: 60, dy: 60)
            drawPhoto(photo, in: context, rect: photoRect)
        }
    }
    
    private func generateSinglePhotoWithDetailsLayout(photos: [UIImage], size: CGSize, eventName: String, eventDate: String) -> UIImage {
        guard let photo = photos.first else {
            return generatePlaceholderImage(size: size, text: "No Photo")
        }
        
        return generateImageWithText(size: size, backgroundColor: .white) { context, rect in
            // Photo area (80% of height)
            let photoHeight = rect.height * 0.8
            let photoRect = CGRect(x: 60, y: 60, width: rect.width - 120, height: photoHeight - 60)
            drawPhoto(photo, in: context, rect: photoRect)
            
            // Text area (20% of height)
            let textY = photoRect.maxY + 30
            let textHeight = rect.height - textY - 60
            
            // Event name
            let nameRect = CGRect(x: 80, y: textY, width: rect.width - 160, height: textHeight * 0.6)
            drawText(eventName, in: context, rect: nameRect, fontSize: 48, color: .black, alignment: .center, weight: .bold)
            
            // Event date
            let dateRect = CGRect(x: 80, y: textY + textHeight * 0.6, width: rect.width - 160, height: textHeight * 0.4)
            drawText(eventDate, in: context, rect: dateRect, fontSize: 36, color: .darkGray, alignment: .center, weight: .medium)
        }
    }
    
    private func generateLargePlusThreeSmallLayout(photos: [UIImage], size: CGSize, eventName: String, eventDate: String) -> UIImage {
        return generateImageWithText(size: size, backgroundColor: .white) { context, rect in
            let margin: CGFloat = 60
            let spacing: CGFloat = 20
            
            // Large photo (top 60% of height)
            let largePhotoHeight = rect.height * 0.6
            let largePhotoRect = CGRect(x: margin, y: margin, width: rect.width - 2*margin, height: largePhotoHeight - margin)
            
            if photos.count > 0 {
                drawPhoto(photos[0], in: context, rect: largePhotoRect)
            } else {
                context.setFillColor(UIColor.lightGray.cgColor)
                context.fill(largePhotoRect)
                drawText("Photo 1", in: context, rect: largePhotoRect, fontSize: 24, color: .darkGray, alignment: .center)
            }
            
            // Bottom section layout
            let bottomY = largePhotoRect.maxY + spacing
            let bottomHeight = rect.height - bottomY - margin
            let smallPhotosWidth = rect.width * 0.6
            let textWidth = rect.width * 0.4 - spacing
            
            // Three small photos (left side of bottom section)
            let smallPhotoHeight = (bottomHeight - 2*spacing) / 3
            
            for i in 0..<3 {
                let photoIndex = i + 1
                let y = bottomY + CGFloat(i) * (smallPhotoHeight + spacing)
                let smallPhotoRect = CGRect(x: margin, y: y, width: smallPhotosWidth - spacing, height: smallPhotoHeight)
                
                if photos.count > photoIndex {
                    drawPhoto(photos[photoIndex], in: context, rect: smallPhotoRect)
                } else {
                    context.setFillColor(UIColor.lightGray.cgColor)
                    context.fill(smallPhotoRect)
                    drawText("Photo \(photoIndex + 1)", in: context, rect: smallPhotoRect, fontSize: 18, color: .darkGray, alignment: .center)
                }
            }
            
            // Text area (right side of bottom section)
            let textRect = CGRect(x: margin + smallPhotosWidth, y: bottomY, width: textWidth, height: bottomHeight)
            
            // Event name
            let nameHeight = textRect.height * 0.4
            let nameRect = CGRect(x: textRect.minX, y: textRect.minY + textRect.height * 0.2, width: textRect.width, height: nameHeight)
            drawText(eventName, in: context, rect: nameRect, fontSize: 32, color: .black, alignment: .center, weight: .bold)
            
            // Event date
            let dateHeight = textRect.height * 0.3
            let dateRect = CGRect(x: textRect.minX, y: nameRect.maxY + 10, width: textRect.width, height: dateHeight)
            drawText(eventDate, in: context, rect: dateRect, fontSize: 24, color: .darkGray, alignment: .center, weight: .medium)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateImageWithText(size: CGSize, backgroundColor: UIColor, drawing: (CGContext, CGRect) -> Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return UIImage()
        }
        
        let rect = CGRect(origin: .zero, size: size)
        
        // Background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        
        // Custom drawing
        drawing(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func generatePlaceholderImage(size: CGSize, text: String) -> UIImage {
        return generateImageWithText(size: size, backgroundColor: .lightGray) { context, rect in
            drawText(text, in: context, rect: rect, fontSize: 24, color: .darkGray, alignment: .center)
        }
    }
    
    private func drawPhoto(_ photo: UIImage, in context: CGContext, rect: CGRect) {
        // Calculate aspect-fit rectangle
        let photoSize = photo.size
        let aspectRatio = photoSize.width / photoSize.height
        let rectAspectRatio = rect.width / rect.height
        
        var drawRect = rect
        if aspectRatio > rectAspectRatio {
            // Photo is wider - fit to width
            let newHeight = rect.width / aspectRatio
            drawRect = CGRect(x: rect.minX, y: rect.midY - newHeight/2, width: rect.width, height: newHeight)
        } else {
            // Photo is taller - fit to height
            let newWidth = rect.height * aspectRatio
            drawRect = CGRect(x: rect.midX - newWidth/2, y: rect.minY, width: newWidth, height: rect.height)
        }
        
        context.saveGState()
        context.clip(to: rect)
        photo.draw(in: drawRect)
        context.restoreGState()
    }
    
    private func drawText(_ text: String, in context: CGContext, rect: CGRect, fontSize: CGFloat, color: UIColor, alignment: NSTextAlignment = .left, weight: UIFont.Weight = .regular) {
        let font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    private func drawCameraIcon(in context: CGContext, rect: CGRect) {
        context.setFillColor(UIColor.systemGray2.cgColor)
        
        // Camera body
        let bodyRect = rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.2)
        context.fillEllipse(in: bodyRect)
        
        // Camera lens
        let lensRect = rect.insetBy(dx: rect.width * 0.3, dy: rect.height * 0.3)
        context.setFillColor(UIColor.systemGray.cgColor)
        context.fillEllipse(in: lensRect)
        
        // Lens center
        let centerRect = rect.insetBy(dx: rect.width * 0.4, dy: rect.height * 0.4)
        context.setFillColor(UIColor.systemGray3.cgColor)
        context.fillEllipse(in: centerRect)
    }
}