import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSnvComponent } from './doc-snv.component';

describe('DocSnvComponent', () => {
  let component: DocSnvComponent;
  let fixture: ComponentFixture<DocSnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
