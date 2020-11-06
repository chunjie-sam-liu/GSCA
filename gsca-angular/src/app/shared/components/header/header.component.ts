import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
})
export class HeaderComponent implements OnInit {
  @Output() toggleSideBarForMe = new EventEmitter<any>();
  public assets = environment.assets;

  constructor() {}

  ngOnInit(): void {}

  toggleSidbeBar() {
    this.toggleSideBarForMe.emit();
  }
}
