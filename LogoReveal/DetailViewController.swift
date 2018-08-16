
import UIKit
import QuartzCore

class DetailViewController: UITableViewController, UINavigationControllerDelegate {
  
  weak var animator: RevealAnimator?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Pack List"
    tableView.rowHeight = 54.0
  }
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let masterVC = navigationController!.viewControllers.first as? MasterViewController {
            animator = masterVC.transition
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        view.addGestureRecognizer(pan)
    }
    
    @objc func didPan(recognizer: UIPanGestureRecognizer) {
        guard let animator = animator else { return }
        
        if recognizer.state == .began {
            animator.interactive = true
            navigationController!.popViewController(animated: true)
        }
        animator.handlePan(recognizer)
    }
    
  // MARK: Table View methods
  let packItems = ["Ice cream money", "Great weather", "Beach ball", "Swimsuit for him", "Swimsuit for her", "Beach games", "Ironing board", "Cocktail mood", "Sunglasses", "Flip flops"]
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
    cell.accessoryType = .none
    cell.textLabel?.text = packItems[(indexPath as NSIndexPath).row]
    cell.imageView?.image = UIImage(named: "summericons_100px_0\((indexPath as NSIndexPath).row).png")
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}
