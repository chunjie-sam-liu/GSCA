import { Component, OnInit } from '@angular/core';
import authors from 'src/app/shared/constants/authors'

@Component({
  selector: 'app-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.css']
})
export class ContactComponent implements OnInit {
  public authors=authors;

  constructor() { }

  ngOnInit(): void {
  }

}
