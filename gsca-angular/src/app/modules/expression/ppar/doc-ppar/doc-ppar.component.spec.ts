import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocPparComponent } from './doc-ppar.component';

describe('DocPparComponent', () => {
  let component: DocPparComponent;
  let fixture: ComponentFixture<DocPparComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocPparComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocPparComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
