import UIKit

class ProgressViewContainer: UIView, NibLoadable {

    @IBOutlet weak var progressView: UIProgressView!

    @IBOutlet weak var label: UILabel!

    var contentView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        sharedInit()
        contentView?.prepareForInterfaceBuilder()
    }

    private func sharedInit() {
        initialize()
        setupViews()
    }

    private func initialize() {
        guard let view = loadFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }

    private func setupViews() {
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.black
        progressView.progressTintColor = UIColor.blue
        progressView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.layer.cornerRadius = progressView.frame.height / 2
    }

    func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: true)
    }

}

protocol NibLoadable {
    func loadFromNib() -> UIView?
}

extension NibLoadable {
    func loadFromNib() -> UIView? {
        let nibName = String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
